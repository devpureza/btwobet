<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Services\PredictionWindow;
use Illuminate\Http\JsonResponse;

class MatchPredictionsController extends Controller
{
    public function __construct(private readonly PredictionWindow $window) {}

    public function index(FootballMatch $match): JsonResponse
    {
        if (! $this->window->communityPredictionsVisible($match)) {
            return response()->json([
                'message' => 'Palpites dos participantes ainda não estão disponíveis.',
            ], 403);
        }

        $showPoints = $match->status === 'finished';

        $predictions = Prediction::query()
            ->with(['user:id,name,avatar_url'])
            ->where('match_id', $match->id)
            ->get()
            ->sortBy(fn (Prediction $prediction) => mb_strtolower($prediction->user->name))
            ->values()
            ->map(fn (Prediction $prediction) => [
                'user' => [
                    'id' => $prediction->user->id,
                    'name' => $prediction->user->name,
                    'avatar_url' => $prediction->user->avatar_url,
                ],
                'home_score' => $prediction->home_score,
                'away_score' => $prediction->away_score,
                'points' => $showPoints ? $prediction->points : null,
            ]);

        return response()->json([
            'match_id' => $match->id,
            'data' => $predictions,
        ]);
    }
}
