<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Services\ScoreSync\FootballDataScoreProvider;
use App\Support\TeamNameMatcher;
use App\Support\TeamSlot;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class WorldCupScoreSyncService
{
    public function __construct(
        private readonly FootballDataScoreProvider $globo,
        private readonly RankingService $rankingService,
        private readonly ScoreSyncStatusService $syncStatus,
    ) {}

    /**
     * @return array{found: int, matched: int, updated: int, finished: int, unmatched: list<string>}
     */
    public function syncFromGloboEsporte(): array
    {
        TeamNameMatcher::resetIndex();
        $this->mirrorBracketTeams();

        $games = $this->globo->fetch();
        $stats = [
            'found' => count($games),
            'matched' => 0,
            'updated' => 0,
            'finished' => 0,
            'unmatched' => [],
        ];

        foreach ($games as $game) {
            $home = TeamNameMatcher::findTeam($game['home_name']);
            $away = TeamNameMatcher::findTeam($game['away_name']);

            if (! $home || ! $away) {
                $stats['unmatched'][] = $game['home_name'].' x '.$game['away_name'];
                continue;
            }

            $match = $this->findMatch($home->id, $away->id, $game['kickoff_at']);
            if (! $match) {
                $stats['unmatched'][] = $game['home_name'].' x '.$game['away_name'].' @ '.$game['kickoff_at']->toIso8601String();
                continue;
            }

            $stats['matched']++;

            $changed = $this->applyScores(
                $match,
                $game['home_score'],
                $game['away_score'],
                (bool) ($game['started'] ?? false),
                (bool) ($game['finished'] ?? false),
            );
            if ($changed) {
                $stats['updated']++;
                if ($match->status === 'finished') {
                    $stats['finished']++;
                }
            }
        }

        if ($stats['unmatched'] !== []) {
            Log::info('globo_esporte.sync.unmatched', ['games' => array_slice($stats['unmatched'], 0, 20)]);
        }

        $this->syncStatus->recordRun($stats);

        return $stats;
    }

    public function recordFailedRun(): void
    {
        $this->syncStatus->recordRun([
            'found' => 0,
            'matched' => 0,
            'updated' => 0,
            'finished' => 0,
            'unmatched' => [],
        ]);
    }

    /** @return array{filled:int} */
    public function mirrorBracketTeams(): array
    {
        TeamNameMatcher::resetIndex();
        $filled = 0;
        foreach ($this->globo->fetchAll() as $g) {
            if ($g['home_name'] === null || $g['away_name'] === null) { continue; }
            $home = TeamNameMatcher::findTeam($g['home_name']);
            $away = TeamNameMatcher::findTeam($g['away_name']);
            if (! $home || ! $away || TeamSlot::isPlaceholder($home) || TeamSlot::isPlaceholder($away)) { continue; }

            $match = FootballMatch::where('external_id', $g['external_id'])->first();
            if (! $match || $match->teams_locked) { continue; }
            $match->loadMissing(['homeTeam', 'awayTeam']);

            $changed = false;
            if (TeamSlot::isPlaceholder($match->homeTeam) && $match->home_team_id !== $home->id) {
                $match->home_team_id = $home->id; $match->setRelation('homeTeam', $home); $changed = true;
            }
            if (TeamSlot::isPlaceholder($match->awayTeam) && $match->away_team_id !== $away->id) {
                $match->away_team_id = $away->id; $match->setRelation('awayTeam', $away); $changed = true;
            }
            if ($changed) {
                if (! TeamSlot::isPlaceholder($match->homeTeam) && ! TeamSlot::isPlaceholder($match->awayTeam) && $match->teams_defined_at === null) {
                    $match->teams_defined_at = now();
                }
                $match->save();
                $filled++;
            }
        }
        return ['filled' => $filled];
    }

    private function findMatch(int $homeId, int $awayId, Carbon $kickoff): ?FootballMatch
    {
        $candidates = FootballMatch::query()
            ->where('home_team_id', $homeId)
            ->where('away_team_id', $awayId)
            ->orderBy('kickoff_at')
            ->get();

        if ($candidates->isEmpty()) {
            return null;
        }

        if ($candidates->count() === 1) {
            return $candidates->first();
        }

        // Horário do GE pode divergir do openfootball (fuso); escolhe o mais próximo.
        return $candidates->sortBy(fn (FootballMatch $m) => abs(
            $m->kickoff_at->diffInMinutes($kickoff, false)
        ))->first();
    }

    private function applyScores(
        FootballMatch $match,
        ?int $homeScore,
        ?int $awayScore,
        bool $geStarted,
        bool $geFinished,
    ): bool {
        $scoresChanged = false;

        if ($homeScore !== null && $awayScore !== null) {
            if ($match->home_score !== $homeScore || $match->away_score !== $awayScore) {
                $match->home_score = $homeScore;
                $match->away_score = $awayScore;
                $scoresChanged = true;
            }
        }

        $hasScores = $match->home_score !== null && $match->away_score !== null;
        // Usa kickoff do banco (openfootball); horário do GE pode divergir por fuso.
        $kickoff = $match->kickoff_at;
        $shouldFinish = $geFinished || ($hasScores && $kickoff->copy()->addMinutes(150)->isPast());

        $statusChanged = false;
        if ($shouldFinish && $match->status !== 'finished') {
            $match->status = 'finished';
            $statusChanged = true;
        } elseif (
            ! $shouldFinish
            && $hasScores
            && ($kickoff->isPast() || $geStarted)
            && $match->status === 'scheduled'
        ) {
            $match->status = 'live';
            $statusChanged = true;
        }

        if (! $scoresChanged && ! $statusChanged) {
            return false;
        }

        $match->save();

        if (in_array($match->status, ['live', 'finished'], true)) {
            $this->rankingService->recalculateForMatch($match->fresh(), new ScoreCalculator());
        }

        return true;
    }
}
