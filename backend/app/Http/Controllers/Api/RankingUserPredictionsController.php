<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Prediction;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class RankingUserPredictionsController extends Controller
{
    public function __invoke(User $user): JsonResponse
    {
        $predictions = Prediction::with(['match.homeTeam', 'match.awayTeam'])
            ->where('user_id', $user->id)
            ->get()
            ->filter(fn (Prediction $p) => $p->match->status === 'finished')
            ->sortByDesc(fn (Prediction $p) => $p->match->kickoff_at)
            ->values()
            ->map(fn (Prediction $p) => [
                'match_id'   => $p->match_id,
                'kickoff_at' => $p->match->kickoff_at?->toIso8601String(),
                'home_team'  => [
                    'name'     => $p->match->homeTeam?->name,
                    'flag_url' => $p->match->homeTeam?->flag_url,
                ],
                'away_team'  => [
                    'name'     => $p->match->awayTeam?->name,
                    'flag_url' => $p->match->awayTeam?->flag_url,
                ],
                'prediction' => [
                    'home_score' => $p->home_score,
                    'away_score' => $p->away_score,
                ],
                'result' => [
                    'home_score' => $p->match->home_score,
                    'away_score' => $p->match->away_score,
                ],
                'points' => $p->points,
            ]);

        return response()->json(['data' => $predictions]);
    }
}
