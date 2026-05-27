<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'approval_status' => User::STATUS_PENDING,
        ]);

        return response()->json([
            'message' => 'Cadastro enviado! Aguarde a aprovação de um administrador.',
            'user' => $user->only(['id', 'name', 'email', 'approval_status', 'created_at']),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Credenciais inválidas.'], 401);
        }

        if ($user->approval_status === User::STATUS_PENDING) {
            return response()->json(['message' => 'Seu cadastro está aguardando aprovação.'], 403);
        }

        if ($user->approval_status === User::STATUS_REJECTED) {
            return response()->json(['message' => 'Seu cadastro foi recusado. Entre em contato com o organizador.'], 403);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()]);
    }

    public function updateMe(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'avatar_url' => ['nullable', 'string', 'max:2048'],
            'password' => ['sometimes', Password::min(8)],
        ]);

        if (array_key_exists('password', $validated)) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $user->fill($validated);
        $user->save();

        return response()->json(['user' => $user->fresh()]);
    }

    public function uploadAvatar(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:png,jpg,jpeg,webp', 'max:5120'],
        ]);

        $file = $validated['file'];
        $ext = strtolower($file->getClientOriginalExtension() ?: 'jpg');
        $filename = 'user-'.$user->id.'.'.$ext;

        $path = $file->storeAs('avatars', $filename, 'public');
        $user->avatar_url = Storage::disk('public')->url($path);
        $user->save();

        return response()->json([
            'message' => 'Foto de perfil atualizada.',
            'user' => $user->fresh(),
        ]);
    }
}
