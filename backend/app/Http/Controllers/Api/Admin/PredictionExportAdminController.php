<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class PredictionExportAdminController extends Controller
{
    public function __invoke(Request $request): StreamedResponse|\Illuminate\Http\JsonResponse
    {
        $validated = $request->validate([
            'format' => ['sometimes', 'string', 'in:csv,json'],
            'user_id' => ['sometimes', 'integer', 'exists:users,id'],
            'email' => ['sometimes', 'string', 'max:255'],
            'match_id' => ['sometimes', 'integer', 'exists:matches,id'],
            'status' => ['sometimes', 'string', 'in:scheduled,finished'],
            'stage' => ['sometimes', 'string', 'in:group,knockout'],
            'group_name' => ['sometimes', 'nullable', 'string', 'size:1', 'regex:/^[A-L]$/i'],
            'created_from' => ['sometimes', 'date'],
            'created_to' => ['sometimes', 'date'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:500'],
        ]);

        $format = (string) ($validated['format'] ?? 'csv');
        $userId = $validated['user_id'] ?? null;
        $email = isset($validated['email']) ? trim((string) $validated['email']) : null;
        $matchId = $validated['match_id'] ?? null;
        $status = $validated['status'] ?? null;
        $stage = $validated['stage'] ?? null;
        $groupName = $validated['group_name'] ?? null;
        if ($groupName !== null) {
            $groupName = strtoupper((string) $groupName);
        }

        $createdFrom = isset($validated['created_from'])
            ? CarbonImmutable::parse($validated['created_from'])->startOfDay()
            : null;
        $createdTo = isset($validated['created_to'])
            ? CarbonImmutable::parse($validated['created_to'])->endOfDay()
            : null;

        $query = DB::table('predictions')
            ->join('users', 'users.id', '=', 'predictions.user_id')
            ->join('matches', 'matches.id', '=', 'predictions.match_id')
            ->join('teams as home_teams', 'home_teams.id', '=', 'matches.home_team_id')
            ->join('teams as away_teams', 'away_teams.id', '=', 'matches.away_team_id')
            ->select([
                'predictions.id as prediction_id',
                'predictions.user_id',
                'users.name as user_name',
                'users.email as user_email',
                'predictions.match_id',
                'matches.kickoff_at as match_kickoff_at',
                'matches.stage as match_stage',
                'matches.group_name as match_group_name',
                'matches.status as match_status',
                'matches.home_score as match_home_score',
                'matches.away_score as match_away_score',
                'home_teams.name as home_team_name',
                'away_teams.name as away_team_name',
                'predictions.home_score as prediction_home_score',
                'predictions.away_score as prediction_away_score',
                'predictions.points as prediction_points',
                'predictions.created_at as prediction_created_at',
                'predictions.updated_at as prediction_updated_at',
            ])
            ->when($userId !== null, fn ($q) => $q->where('predictions.user_id', (int) $userId))
            ->when($email !== null && $email !== '', fn ($q) => $q->where('users.email', 'ilike', '%'.$email.'%'))
            ->when($matchId !== null, fn ($q) => $q->where('predictions.match_id', (int) $matchId))
            ->when($status !== null, fn ($q) => $q->where('matches.status', $status))
            ->when($stage !== null, fn ($q) => $q->where('matches.stage', $stage))
            ->when($groupName !== null, fn ($q) => $q->where('matches.group_name', $groupName))
            ->when($createdFrom !== null, fn ($q) => $q->where('predictions.created_at', '>=', $createdFrom))
            ->when($createdTo !== null, fn ($q) => $q->where('predictions.created_at', '<=', $createdTo))
            ->orderBy('predictions.id');

        if ($format === 'json') {
            $page = (int) ($validated['page'] ?? 1);
            $perPage = (int) ($validated['per_page'] ?? 200);
            $paginator = $query->paginate($perPage, ['*'], 'page', $page);

            return response()->json([
                'data' => $paginator->items(),
                'meta' => [
                    'current_page' => $paginator->currentPage(),
                    'per_page' => $paginator->perPage(),
                    'total' => $paginator->total(),
                    'last_page' => $paginator->lastPage(),
                ],
            ]);
        }

        $filename = 'palpites_'.CarbonImmutable::now('UTC')->format('Ymd_His').'.csv';
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ];

        return response()->streamDownload(function () use ($query) {
            $out = fopen('php://output', 'w');
            if ($out === false) {
                return;
            }

            // UTF-8 BOM para melhor compatibilidade com Excel (pt-BR).
            fwrite($out, "\xEF\xBB\xBF");

            fputcsv($out, [
                'prediction_id',
                'user_id',
                'user_name',
                'user_email',
                'match_id',
                'match_kickoff_at',
                'match_stage',
                'match_group_name',
                'match_status',
                'home_team',
                'away_team',
                'prediction_home_score',
                'prediction_away_score',
                'match_home_score',
                'match_away_score',
                'points',
                'created_at',
                'updated_at',
            ]);

            foreach ($query->cursor() as $row) {
                fputcsv($out, [
                    $row->prediction_id,
                    $row->user_id,
                    $row->user_name,
                    $row->user_email,
                    $row->match_id,
                    $row->match_kickoff_at,
                    $row->match_stage,
                    $row->match_group_name,
                    $row->match_status,
                    $row->home_team_name,
                    $row->away_team_name,
                    $row->prediction_home_score,
                    $row->prediction_away_score,
                    $row->match_home_score,
                    $row->match_away_score,
                    $row->prediction_points,
                    $row->prediction_created_at,
                    $row->prediction_updated_at,
                ]);
            }

            fclose($out);
        }, $filename, $headers);
    }
}

