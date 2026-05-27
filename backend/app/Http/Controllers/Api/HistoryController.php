<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Prediction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HistoryController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $predictions = Prediction::with(['match.homeTeam', 'match.awayTeam'])
            ->where('user_id', $request->user()->id)
            ->orderByDesc('updated_at')
            ->get()
            ->map(fn (Prediction $prediction) => [
                'match_id' => $prediction->match_id,
                'kickoff_at' => $prediction->match->kickoff_at->toIso8601String(),
                'home_team' => $prediction->match->homeTeam->name,
                'away_team' => $prediction->match->awayTeam->name,
                'prediction' => [
                    'home_score' => $prediction->home_score,
                    'away_score' => $prediction->away_score,
                ],
                'result' => $prediction->match->status === 'finished' ? [
                    'home_score' => $prediction->match->home_score,
                    'away_score' => $prediction->match->away_score,
                ] : null,
                'points' => $prediction->points,
                'status' => $prediction->match->status,
            ]);

        return response()->json([
            'total_points' => (int) $predictions->sum('points'),
            'data' => $predictions,
        ]);
    }
}
