<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AchievementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AchievementController extends Controller
{
    public function __construct(private readonly AchievementService $achievements) {}

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $newlyUnlocked = $this->achievements->evaluateForUser($user);
        $payload = $this->achievements->catalogForUser($user);
        $payload['newly_unlocked'] = $newlyUnlocked;

        return response()->json(['data' => $payload]);
    }
}
