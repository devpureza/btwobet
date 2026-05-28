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
            return [
                'position' => $index + 1,
                'user_id' => $row->id,
                'name' => $row->name,
                'avatar_url' => $row->avatar_url,
                'total_points' => (int) $row->total_points,
                'exact_hits' => (int) $row->exact_hits,
                'result_hits' => (int) $row->result_hits,
            ];
        });

        return response()->json(['data' => $ranking]);
    }
}
