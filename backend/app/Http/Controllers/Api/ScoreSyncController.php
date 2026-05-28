<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ScoreSyncStatusService;
use Illuminate\Http\JsonResponse;

class ScoreSyncController extends Controller
{
    public function __invoke(ScoreSyncStatusService $status): JsonResponse
    {
        return response()->json($status->toArray());
    }
}
