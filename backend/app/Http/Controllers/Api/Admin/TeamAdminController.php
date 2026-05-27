<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TeamAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = trim((string) $request->query('q', ''));
        $group = trim((string) $request->query('group', ''));

        $teams = Team::query()
            ->when($q !== '', function ($query) use ($q) {
                $query->where('name', 'ilike', '%'.$q.'%')
                    ->orWhere('code', 'ilike', '%'.$q.'%');
            })
            ->when($group !== '', fn ($query) => $query->where('group_name', strtoupper($group)))
            ->orderBy('group_name')
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'group_name', 'flag_url', 'created_at', 'updated_at']);

        return response()->json(['data' => $teams]);
    }

    public function update(Request $request, Team $team): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['sometimes', 'string', 'size:3', 'unique:teams,code,'.$team->id],
            'name' => ['sometimes', 'string', 'max:255'],
            'group_name' => ['nullable', 'string', 'size:1', 'regex:/^[A-H]$/i'],
            'flag_url' => ['nullable', 'string', 'max:2048'],
        ]);

        if (array_key_exists('code', $validated)) {
            $validated['code'] = strtoupper((string) $validated['code']);
        }
        if (array_key_exists('group_name', $validated) && $validated['group_name'] !== null) {
            $validated['group_name'] = strtoupper((string) $validated['group_name']);
        }

        $team->fill($validated);
        $team->save();

        return response()->json(['data' => $team->fresh(['id', 'code', 'name', 'group_name', 'flag_url'])]);
    }

    public function uploadFlag(Request $request, Team $team): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:png,jpg,jpeg,webp', 'max:5120'],
        ]);

        $file = $validated['file'];
        $ext = strtolower($file->getClientOriginalExtension() ?: 'png');

        $code = strtolower($team->code);
        $filename = $code.'.'.$ext;

        $flagsDir = public_path('flags');
        if (! is_dir($flagsDir)) {
            mkdir($flagsDir, 0775, true);
        }

        $file->move($flagsDir, $filename);

        $team->flag_url = '/flags/'.$filename;
        $team->save();

        return response()->json([
            'message' => 'Bandeira atualizada.',
            'data' => [
                'team_id' => $team->id,
                'flag_url' => $team->flag_url,
            ],
        ]);
    }
}

