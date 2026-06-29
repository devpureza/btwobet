<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\FootballMatch;
use App\Services\RankingService;
use App\Services\ScoreCalculator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MatchAdminController extends Controller
{
    public function __construct(private readonly RankingService $rankingService) {}

    public function index(Request $request): JsonResponse
    {
        $group = trim((string) $request->query('group', ''));
        $stage = trim((string) $request->query('stage', ''));
        $status = trim((string) $request->query('status', ''));

        $matches = FootballMatch::with(['homeTeam', 'awayTeam'])
            ->when($group !== '', fn ($q) => $q->where('group_name', strtoupper($group)))
            ->when($stage !== '', fn ($q) => $q->where('stage', $stage))
            ->when($status !== '', fn ($q) => $q->where('status', $status))
            ->orderBy('kickoff_at')
            ->get();

        $data = $matches->map(function (FootballMatch $m) {
            return [
                'id' => $m->id,
                'kickoff_at' => $m->kickoff_at->toIso8601String(),
                'stage' => $m->stage,
                'group_name' => $m->group_name,
                'venue' => $m->venue,
                'status' => $m->status,
                'home_score' => $m->home_score,
                'away_score' => $m->away_score,
                'score_locked' => $m->score_locked,
                'home_team' => [
                    'id' => $m->homeTeam->id,
                    'code' => $m->homeTeam->code,
                    'name' => $m->homeTeam->name,
                    'flag_url' => $m->homeTeam->flag_url,
                ],
                'away_team' => [
                    'id' => $m->awayTeam->id,
                    'code' => $m->awayTeam->code,
                    'name' => $m->awayTeam->name,
                    'flag_url' => $m->awayTeam->flag_url,
                ],
            ];
        });

        return response()->json(['data' => $data]);
    }

    public function updateResult(Request $request, FootballMatch $match): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['required', 'string', 'in:scheduled,live,finished'],
            'home_score' => ['nullable', 'integer', 'min:0', 'max:30'],
            'away_score' => ['nullable', 'integer', 'min:0', 'max:30'],
        ]);

        $status = (string) $validated['status'];
        $home = $validated['home_score'] ?? null;
        $away = $validated['away_score'] ?? null;

        if (in_array($status, ['live', 'finished'], true) && ($home === null || $away === null)) {
            return response()->json(['message' => 'Informe o placar para marcar o jogo ao vivo ou finalizado.'], 422);
        }

        $match->status = $status;
        if ($status === 'scheduled') {
            $match->home_score = null;
            $match->away_score = null;
        } else {
            $match->home_score = $home;
            $match->away_score = $away;
        }
        $match->score_locked = ($status !== 'scheduled');
        $match->save();

        // Recalcula pontos dos palpites do jogo (idempotente).
        $this->rankingService->recalculateForMatch($match->fresh(), new ScoreCalculator());

        return response()->json(['message' => 'Resultado atualizado.', 'data' => ['id' => $match->id]]);
    }

    public function update(Request $request, FootballMatch $match): JsonResponse
    {
        $validated = $request->validate([
            'kickoff_at' => ['sometimes', 'date'],
            'stage' => ['sometimes', 'string', 'in:group,knockout'],
            'group_name' => ['nullable', 'string', 'size:1', 'regex:/^[A-L]$/i'],
            'venue' => ['nullable', 'string', 'max:255'],
            'status' => ['sometimes', 'string', 'in:scheduled,live,finished'],
            'home_team_id' => ['sometimes', 'integer', 'exists:teams,id'],
            'away_team_id' => ['sometimes', 'integer', 'exists:teams,id'],
            'score_locked' => ['sometimes', 'boolean'],
        ]);

        if (array_key_exists('group_name', $validated) && $validated['group_name'] !== null) {
            $validated['group_name'] = strtoupper((string) $validated['group_name']);
        }

        // Se status for scheduled, zera placar.
        if (($validated['status'] ?? null) === 'scheduled') {
            $match->home_score = null;
            $match->away_score = null;
        }

        if (array_key_exists('home_team_id', $validated) || array_key_exists('away_team_id', $validated)) {
            $validated['teams_locked'] = true;
        }

        $match->fill($validated);
        $match->save();

        $match->loadMissing(['homeTeam', 'awayTeam']);
        if ($match->teams_defined_at === null
            && ! \App\Support\TeamSlot::isPlaceholder($match->homeTeam)
            && ! \App\Support\TeamSlot::isPlaceholder($match->awayTeam)) {
            $match->teams_defined_at = now();
            $match->save();
        }

        return response()->json(['message' => 'Jogo atualizado.', 'data' => ['id' => $match->id]]);
    }
}

