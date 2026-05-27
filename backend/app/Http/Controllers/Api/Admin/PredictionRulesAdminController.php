<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\BolaoSettings;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PredictionRulesAdminController extends Controller
{
    public function show(BolaoSettings $settings): JsonResponse
    {
        $data = $settings->all();

        return response()->json([
            'data' => [
                'group_deadline' => $data['group_deadline'],
                'knockout_hours_before' => $data['knockout_hours_before'],
                'lock_all' => $data['lock_all'],
            ],
        ]);
    }

    public function update(Request $request, BolaoSettings $settings): JsonResponse
    {
        $validated = $request->validate([
            'group_deadline' => ['sometimes', 'date'],
            'knockout_hours_before' => ['sometimes', 'integer', 'min:0', 'max:168'],
            'lock_all' => ['sometimes', 'boolean'],
        ]);

        $updated = $settings->update($validated);

        return response()->json([
            'message' => 'Regras de palpite atualizadas.',
            'data' => [
                'group_deadline' => $updated['group_deadline'],
                'knockout_hours_before' => $updated['knockout_hours_before'],
                'lock_all' => $updated['lock_all'],
            ],
        ]);
    }
}
