<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Prediction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserPredictionsAdminController extends Controller
{
    public function clear(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'match_id' => ['sometimes', 'integer', 'exists:matches,id'],
            'status' => ['sometimes', 'string', 'in:scheduled,finished'],
            'stage' => ['sometimes', 'string', 'in:group,knockout'],
            'group_name' => ['sometimes', 'nullable', 'string', 'size:1', 'regex:/^[A-L]$/i'],
        ]);

        $matchId = $validated['match_id'] ?? null;
        $status = $validated['status'] ?? null;
        $stage = $validated['stage'] ?? null;
        $groupName = $validated['group_name'] ?? null;
        if ($groupName !== null) {
            $groupName = strtoupper((string) $groupName);
        }

        $deleted = DB::transaction(function () use ($user, $matchId, $status, $stage, $groupName): int {
            return Prediction::query()
                ->where('user_id', $user->id)
                ->when($matchId !== null, fn ($q) => $q->where('match_id', (int) $matchId))
                ->when($status !== null || $stage !== null || $groupName !== null, function ($q) use ($status, $stage, $groupName) {
                    $q->whereHas('match', function ($mq) use ($status, $stage, $groupName) {
                        $mq->when($status !== null, fn ($inner) => $inner->where('status', $status))
                            ->when($stage !== null, fn ($inner) => $inner->where('stage', $stage))
                            ->when($groupName !== null, fn ($inner) => $inner->where('group_name', $groupName));
                    });
                })
                ->delete();
        });

        return response()->json([
            'message' => 'Palpites removidos.',
            'data' => [
                'user_id' => $user->id,
                'deleted' => $deleted,
                'filters' => [
                    'match_id' => $matchId,
                    'status' => $status,
                    'stage' => $stage,
                    'group_name' => $groupName,
                ],
            ],
        ]);
    }
}

