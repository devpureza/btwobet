<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class UserAdminController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = trim((string) $request->query('q', ''));

        $users = User::query()
            ->when($q !== '', function ($query) use ($q) {
                $query->where('name', 'ilike', '%'.$q.'%')
                    ->orWhere('email', 'ilike', '%'.$q.'%');
            })
            ->orderBy('name')
            ->limit(200)
            ->get(['id', 'name', 'email', 'is_admin', 'avatar_url', 'created_at', 'updated_at']);

        return response()->json(['data' => $users]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', Password::min(8)],
            'avatar_url' => ['nullable', 'string', 'max:2048'],
            'is_admin' => ['sometimes', 'boolean'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'avatar_url' => $validated['avatar_url'] ?? null,
            'is_admin' => (bool) ($validated['is_admin'] ?? false),
        ]);

        return response()->json(['data' => $user], 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', 'unique:users,email,'.$user->id],
            'password' => ['sometimes', Password::min(8)],
            'avatar_url' => ['nullable', 'string', 'max:2048'],
            'is_admin' => ['sometimes', 'boolean'],
        ]);

        if (array_key_exists('password', $validated)) {
            $validated['password'] = Hash::make($validated['password']);
        }

        // Evita que admin se remova acidentalmente
        if ($request->user()?->id === $user->id && array_key_exists('is_admin', $validated) && ! $validated['is_admin']) {
            return response()->json(['message' => 'Você não pode remover seu próprio acesso de admin.'], 422);
        }

        $user->fill($validated);
        $user->save();

        return response()->json(['data' => $user->fresh(['id', 'name', 'email', 'is_admin', 'avatar_url', 'created_at', 'updated_at'])]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($request->user()?->id === $user->id) {
            return response()->json(['message' => 'Você não pode excluir sua própria conta.'], 422);
        }

        $user->delete();
        return response()->json(['message' => 'Participante removido.']);
    }
}

