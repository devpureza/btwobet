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

        return $stats;
    }

    private function findMatch(int $homeId, int $awayId, Carbon $kickoff): ?FootballMatch
    {
        $from = $kickoff->copy()->subHours(2);
        $to = $kickoff->copy()->addHours(2);

        return FootballMatch::query()
            ->where('home_team_id', $homeId)
            ->where('away_team_id', $awayId)
            ->whereBetween('kickoff_at', [$from, $to])
            ->first();
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
