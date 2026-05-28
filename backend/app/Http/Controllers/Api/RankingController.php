<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RankingService;
use Illuminate\Http\JsonResponse;

class RankingController extends Controller
{
    public function __construct(private readonly RankingService $rankingService) {}

    public function index(): JsonResponse
    {
        $ranking = $this->rankingService->getRanking()->values()->map(function ($row, $index) {
            $scored = (int) $row->scored_predictions;
            $exactHits = (int) $row->exact_hits;
            $resultHits = (int) $row->result_hits;

            return [
                'position' => $index + 1,
                'user_id' => $row->id,
                'name' => $row->name,
                'avatar_url' => $row->avatar_url,
                'total_points' => (int) $row->total_points,
                'total_predictions' => (int) $row->total_predictions,
                'scored_predictions' => $scored,
                'exact_hits' => $exactHits,
                'result_hits' => $resultHits,
                'exact_hit_percent' => $scored > 0 ? (int) round(($exactHits / $scored) * 100) : 0,
                'result_hit_percent' => $scored > 0 ? (int) round(($resultHits / $scored) * 100) : 0,
            ];
        });

        return response()->json(['data' => $ranking]);
    }
}
