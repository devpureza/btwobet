<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Models\Prediction;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class RankingService
{
    public function getRanking(): Collection
    {
        return DB::table('users')
            ->where('users.approval_status', 'approved')
            ->leftJoin('predictions', 'users.id', '=', 'predictions.user_id')
            ->leftJoin('matches', 'predictions.match_id', '=', 'matches.id')
            ->select([
                'users.id',
                'users.name',
                'users.avatar_url',
                DB::raw('COALESCE(SUM(predictions.points), 0) as total_points'),
                DB::raw('COUNT(predictions.id) as total_predictions'),
                DB::raw("SUM(CASE WHEN matches.status IN ('live', 'finished') THEN 1 ELSE 0 END) as scored_predictions"),
                DB::raw('SUM(CASE WHEN predictions.points = 2 THEN 1 ELSE 0 END) as exact_hits'),
                DB::raw('SUM(CASE WHEN predictions.points >= 1 THEN 1 ELSE 0 END) as result_hits'),
                'users.created_at',
            ])
            ->groupBy('users.id', 'users.name', 'users.avatar_url', 'users.created_at')
            ->orderByDesc('total_points')
            ->orderByDesc('exact_hits')
            ->orderByDesc('result_hits')
            ->orderBy('users.created_at')
            ->get();
    }

    public function recalculateForMatch(FootballMatch $match, ScoreCalculator $calculator): void
    {
        if (! in_array($match->status, ['live', 'finished'], true)
            || $match->home_score === null
            || $match->away_score === null) {
            return;
        }

        Prediction::where('match_id', $match->id)->each(function (Prediction $prediction) use ($match, $calculator) {
            $points = $calculator->calculate(
                $prediction->home_score,
                $prediction->away_score,
                $match->home_score,
                $match->away_score,
            );

            $prediction->update(['points' => $points]);
        });

        if ($match->status === 'finished') {
            app(AchievementService::class)->evaluateUsersForFinishedMatch($match->fresh());
        }
    }
}
