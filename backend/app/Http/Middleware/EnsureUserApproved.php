<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserApproved
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user) {
            return $next($request);
        }

        if ($user->approval_status === 'pending') {
            return response()->json([
                'message' => 'Seu cadastro está aguardando aprovação.',
            ], 403);
        }

        if ($user->approval_status === 'rejected') {
            return response()->json([
                'message' => 'Seu cadastro foi recusado. Entre em contato com o organizador.',
            ], 403);
        }

        return $next($request);
    }
}
