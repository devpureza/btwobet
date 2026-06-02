<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Services\AchievementService;
use App\Services\PredictionWindow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PredictionController extends Controller
{
    public function __construct(
        private readonly PredictionWindow $window,
        private readonly AchievementService $achievements,
    ) {}

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'match_id' => ['required', 'integer', 'exists:matches,id'],
            'home_score' => ['required', 'integer', 'min:0', 'max:20'],
            'away_score' => ['required', 'integer', 'min:0', 'max:20'],
        ]);

        $match = FootballMatch::findOrFail($validated['match_id']);

        $existing = Prediction::query()
            ->where('user_id', $request->user()->id)
            ->where('match_id', $match->id)
            ->first();

        $access = $this->window->evaluate($match, $existing);

        if (! $access['can_submit']) {
            return response()->json([
                'message' => $access['reason'] ?? 'Palpites fechados para este jogo.',
            ], 422);
        }

        $prediction = Prediction::create([
            'user_id' => $request->user()->id,
            'match_id' => $match->id,
            'home_score' => $validated['home_score'],
            'away_score' => $validated['away_score'],
            'points' => 0,
        ]);

        $newAchievements = $this->achievements->evaluateAndUnlock(
            $request->user(),
            $prediction->fresh(),
            $match,
        );

        return response()->json([
            'message' => 'Palpite salvo. Não será possível alterar.',
            'data' => $prediction,
            'new_achievements' => $newAchievements,
        ], 201);
    }
}
