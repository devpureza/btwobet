<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Services\PredictionWindow;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PredictionHistoryAdminController extends Controller
{
    public function __construct(private readonly PredictionWindow $window) {}

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'q' => ['sometimes', 'string', 'max:255'],
        ]);

        $page = (int) ($validated['page'] ?? 1);
        $perPage = (int) ($validated['per_page'] ?? 25);
        $q = trim((string) ($validated['q'] ?? ''));

        $query = Prediction::query()
            ->with(['user:id,name,email,avatar_url', 'match.homeTeam', 'match.awayTeam'])
            ->when($q !== '', function ($builder) use ($q) {
                $builder->where(function ($inner) use ($q) {
                    $inner->whereHas('user', function ($userQuery) use ($q) {
                        $userQuery->where('name', 'ilike', '%'.$q.'%')
                            ->orWhere('email', 'ilike', '%'.$q.'%');
                    })->orWhereHas('match.homeTeam', function ($teamQuery) use ($q) {
                        $teamQuery->where('name', 'ilike', '%'.$q.'%');
                    })->orWhereHas('match.awayTeam', function ($teamQuery) use ($q) {
                        $teamQuery->where('name', 'ilike', '%'.$q.'%');
                    });
                });
            })
            ->orderByDesc('created_at');

        $paginator = $query->paginate($perPage, ['*'], 'page', $page);

        $data = $paginator->getCollection()->map(fn (Prediction $prediction) => $this->payload($prediction));

        return response()->json([
            'data' => $data->values(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Prediction $prediction): array
    {
        $match = $prediction->match;
        $submittedAt = $prediction->created_at;

        return [
            'id' => $prediction->id,
            'user' => [
                'id' => $prediction->user->id,
                'name' => $prediction->user->name,
                'email' => $prediction->user->email,
                'avatar_url' => $prediction->user->avatar_url,
            ],
            'match' => [
                'id' => $match->id,
                'home_team' => $match->homeTeam->name,
                'away_team' => $match->awayTeam->name,
                'kickoff_at' => $match->kickoff_at->toIso8601String(),
                'stage' => $match->stage,
                'group_name' => $match->group_name,
                'status' => $match->status,
            ],
            'prediction' => [
                'home_score' => $prediction->home_score,
                'away_score' => $prediction->away_score,
            ],
            'result' => $match->status === 'finished' ? [
                'home_score' => $match->home_score,
                'away_score' => $match->away_score,
            ] : null,
            'points' => $prediction->points,
            'submission' => [
                'window_open_at_submission' => $this->wasWindowOpenAtSubmission($match, $submittedAt),
                'deadline_at' => $this->window->deadlineForMatch($match)?->toIso8601String(),
            ],
            'created_at' => $prediction->created_at?->toIso8601String(),
            'updated_at' => $prediction->updated_at?->toIso8601String(),
        ];
    }

    private function wasWindowOpenAtSubmission(FootballMatch $match, ?Carbon $submittedAt): ?bool
    {
        if ($submittedAt === null) {
            return null;
        }

        return Carbon::withTestNow($submittedAt, fn () => $this->window->isOpenForNewPredictions($match));
    }
}
