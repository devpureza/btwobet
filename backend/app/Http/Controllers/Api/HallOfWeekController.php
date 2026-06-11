<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\HallOfWeekService;
use Illuminate\Http\JsonResponse;

class HallOfWeekController extends Controller
{
    public function __invoke(HallOfWeekService $hall): JsonResponse
    {
        return response()->json($hall->getHallOfWeek());
    }
}
