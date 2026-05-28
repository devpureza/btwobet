<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Services\ScoreSync\GloboEsporteScoreProvider;
use App\Support\TeamNameMatcher;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class WorldCupScoreSyncService
{
    public function __construct(
        private readonly GloboEsporteScoreProvider $globo,
        private readonly RankingService $rankingService,
        private readonly ScoreSyncStatusService $syncStatus,
    ) {}

    /**
     * @return array{found: int, matched: int, updated: int, finished: int, unmatched: list<string>}
     */
    public function syncFromGloboEsporte(): array
    {
        TeamNameMatcher::resetIndex();

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

            $changed = $this->applyScores($match, $game['home_score'], $game['away_score'], $game['kickoff_at']);
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
        Carbon $kickoff,
    ): bool {
        $changed = false;

        if ($homeScore !== null && $awayScore !== null) {
            if ($match->home_score !== $homeScore || $match->away_score !== $awayScore) {
                $match->home_score = $homeScore;
                $match->away_score = $awayScore;
                $changed = true;
            }
        }

        $shouldFinish = $homeScore !== null
            && $awayScore !== null
            && $kickoff->copy()->addMinutes(105)->isPast();

        if ($shouldFinish && $match->status !== 'finished') {
            $match->status = 'finished';
            $changed = true;
        }

        if (! $changed) {
            return false;
        }

        $match->save();

        if ($match->status === 'finished') {
            $this->rankingService->recalculateForMatch($match->fresh(), new ScoreCalculator());
        }

        return true;
    }
}
