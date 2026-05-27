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
        $approvalStatus = trim((string) $request->query('approval_status', ''));

        $users = User::query()
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($inner) use ($q) {
                    $inner->where('name', 'ilike', '%'.$q.'%')
                        ->orWhere('email', 'ilike', '%'.$q.'%');
                });
            })
            ->when(
                in_array($approvalStatus, [User::STATUS_PENDING, User::STATUS_APPROVED, User::STATUS_REJECTED], true),
                fn ($query) => $query->where('approval_status', $approvalStatus),
            )
            ->orderByRaw("CASE approval_status WHEN 'pending' THEN 0 ELSE 1 END")
            ->orderBy('name')
            ->limit(200)
            ->get(['id', 'name', 'email', 'is_admin', 'avatar_url', 'approval_status', 'created_at', 'updated_at']);

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
            'approval_status' => User::STATUS_APPROVED,
        ]);

        return response()->json(['data' => $this->userPayload($user)], 201);
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

        return response()->json(['data' => $this->userPayload($user->fresh())]);
    }

    public function approve(User $user): JsonResponse
    {
        if ($user->approval_status === User::STATUS_APPROVED) {
            return response()->json(['message' => 'Participante já está aprovado.'], 422);
        }

        $user->update(['approval_status' => User::STATUS_APPROVED]);

        return response()->json([
            'message' => 'Cadastro aprovado.',
            'data' => $this->userPayload($user->fresh()),
        ]);
    }

    public function reject(User $user): JsonResponse
    {
        if ($user->approval_status === User::STATUS_REJECTED) {
            return response()->json(['message' => 'Participante já está recusado.'], 422);
        }

        $user->tokens()->delete();
        $user->update(['approval_status' => User::STATUS_REJECTED]);

        return response()->json([
            'message' => 'Cadastro recusado.',
            'data' => $this->userPayload($user->fresh()),
        ]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        if ($request->user()?->id === $user->id) {
            return response()->json(['message' => 'Você não pode excluir sua própria conta.'], 422);
        }

        $user->delete();
        return response()->json(['message' => 'Participante removido.']);
    }

    /** @return array<string, mixed> */
    private function userPayload(User $user): array
    {
        return $user->only(['id', 'name', 'email', 'is_admin', 'avatar_url', 'approval_status', 'created_at', 'updated_at']);
    }
}

