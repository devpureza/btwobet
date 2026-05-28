<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\BolaoFundService;
use Illuminate\Http\JsonResponse;

class BolaoFundController extends Controller
{
    public function __invoke(BolaoFundService $fund): JsonResponse
    {
        return response()->json($fund->stats());
    }
}
