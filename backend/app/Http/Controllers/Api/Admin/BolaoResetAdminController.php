<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\BolaoResetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BolaoResetAdminController extends Controller
{
    public function __invoke(Request $request, BolaoResetService $reset): JsonResponse
    {
        $validated = $request->validate([
            'scope' => ['required', 'string', 'in:game,bolao'],
            'confirm' => ['required', 'string', 'in:RESET'],
        ]);

        $scope = (string) $validated['scope'];

        $stats = $scope === 'game'
            ? $reset->resetGameState()
            : $reset->resetBolaoTables();

        $messages = [
            'game' => 'Palpites e placares zerados.',
            'bolao' => 'Dados do bolão (palpites, jogos e times) removidos.',
        ];

        return response()->json([
            'message' => $messages[$scope],
            'data' => [
                'scope' => $scope,
                'stats' => $stats,
            ],
        ]);
    }
}
