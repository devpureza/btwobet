<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\WorldCupScoreSyncService;
use Illuminate\Http\JsonResponse;

class WorldCupSyncScoresAdminController extends Controller
{
    public function __invoke(WorldCupScoreSyncService $sync): JsonResponse
    {
        try {
            $stats = $sync->syncFromGloboEsporte();
        } catch (\Throwable $e) {
            $sync->recordFailedRun();

            return response()->json([
                'message' => 'Falha ao sincronizar placares do GE.',
                'error' => $e->getMessage(),
            ], 502);
        }

        return response()->json([
            'message' => 'Sincronização concluída.',
            'data' => [
                'found' => $stats['found'],
                'matched' => $stats['matched'],
                'updated' => $stats['updated'],
                'finished' => $stats['finished'],
                'unmatched_count' => count($stats['unmatched']),
            ],
        ]);
    }
}
