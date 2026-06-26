<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AchievementService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class MirrorImport extends Command
{
    protected $signature = 'mirror:import';
    protected $description = 'Importa o estado de producao (storage/app/prod_mirror) para o banco local';

    public function handle(): int
    {
        $dir = storage_path('app/prod_mirror');
        $load = fn ($f) => json_decode(file_get_contents($dir.'/'.$f), true);

        $users = $load('users.json')['body']['data'];
        $teams = $load('teams.json')['body']['data'];
        $matches = $load('matches_admin.json')['body']['data'];
        $rules = $load('prediction_rules.json')['body']['data'];
        $sync = $load('score_sync.json')['body'];

        $lines = file($dir.'/predictions_export.csv', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $header = str_getcsv(array_shift($lines));
        $idx = array_flip($header);

        DB::transaction(function () use ($users, $teams, $matches, $rules, $sync, $lines, $idx) {
            $now = now();
            DB::table('predictions')->delete();
            DB::table('user_achievements')->delete();
            DB::table('matches')->delete();
            DB::table('settings')->delete();
            DB::table('teams')->delete();
            DB::table('users')->delete();

            foreach ($teams as $t) {
                DB::table('teams')->insert([
                    'id' => $t['id'], 'code' => $t['code'] ?? null, 'name' => $t['name'],
                    'flag_url' => $t['flag_url'] ?? null, 'group_name' => $t['group_name'] ?? null,
                    'created_at' => $t['created_at'] ?? $now, 'updated_at' => $t['updated_at'] ?? $now,
                ]);
            }
            foreach ($users as $u) {
                DB::table('users')->insert([
                    'id' => $u['id'], 'name' => $u['name'], 'email' => $u['email'],
                    'email_verified_at' => $u['created_at'] ?? $now,
                    'password' => Hash::make('mirror-'.$u['id']),
                    'is_admin' => ! empty($u['is_admin']) ? 1 : 0,
                    'avatar_url' => $u['avatar_url'] ?? null,
                    'approval_status' => $u['approval_status'] ?? 'approved',
                    'created_at' => $u['created_at'] ?? $now, 'updated_at' => $u['updated_at'] ?? $now,
                ]);
            }
            foreach ($matches as $m) {
                DB::table('matches')->insert([
                    'id' => $m['id'],
                    'home_team_id' => $m['home_team']['id'] ?? null,
                    'away_team_id' => $m['away_team']['id'] ?? null,
                    'kickoff_at' => $m['kickoff_at'], 'stage' => $m['stage'],
                    'group_name' => $m['group_name'] ?? null, 'venue' => $m['venue'] ?? null,
                    'status' => $m['status'],
                    'home_score' => $m['home_score'], 'away_score' => $m['away_score'],
                    'created_at' => $now, 'updated_at' => $now,
                ]);
            }
            $rows = [];
            foreach ($lines as $line) {
                $r = str_getcsv($line);
                if (count($r) < count($idx)) { continue; }
                $rows[] = [
                    'id' => (int) $r[$idx['prediction_id']],
                    'user_id' => (int) $r[$idx['user_id']],
                    'match_id' => (int) $r[$idx['match_id']],
                    'home_score' => (int) $r[$idx['prediction_home_score']],
                    'away_score' => (int) $r[$idx['prediction_away_score']],
                    'points' => $r[$idx['points']] === '' ? 0 : (int) $r[$idx['points']],
                    'created_at' => $r[$idx['created_at']] ?: $now,
                    'updated_at' => $r[$idx['updated_at']] ?: $now,
                ];
            }
            foreach (array_chunk($rows, 500) as $chunk) {
                DB::table('predictions')->insert($chunk);
            }
            $set = function ($k, $v) {
                DB::table('settings')->insert(['key' => $k, 'value' => $v, 'created_at' => now(), 'updated_at' => now()]);
            };
            $set('predictions.group_deadline', Carbon::parse($rules['group_deadline'])->toIso8601String());
            $set('predictions.knockout_hours_before', (string) ($rules['knockout_hours_before'] ?? 24));
            $set('predictions.lock_all', ! empty($rules['lock_all']) ? '1' : '0');
            $set('tournament.tournament_closed', ! empty($rules['tournament_closed']) ? '1' : '0');
            if (! empty($sync['last_sync_at'])) { $set('score_sync.last_at', $sync['last_sync_at']); }
            if (isset($sync['last_updated_matches'])) { $set('score_sync.last_updated_matches', (string) $sync['last_updated_matches']); }
        });

        foreach (['users', 'teams', 'matches', 'predictions'] as $tbl) {
            DB::statement("SELECT setval(pg_get_serial_sequence('$tbl','id'), COALESCE((SELECT MAX(id) FROM $tbl),1), true)");
        }
        Cache::forget('bolao.settings.all');

        $svc = app(AchievementService::class);
        $n = 0;
        foreach (User::all() as $u) {
            try { $svc->evaluateForUser($u); } catch (\Throwable $e) { $this->warn('ach user '.$u->id.': '.$e->getMessage()); }
            $n++;
        }
        try { $svc->evaluateRankingForAllUsers(); } catch (\Throwable $e) { $this->warn('ranking: '.$e->getMessage()); }

        $this->info(sprintf(
            'OK | teams=%d users=%d matches=%d predictions=%d user_achievements=%d (avaliados %d users)',
            DB::table('teams')->count(), DB::table('users')->count(), DB::table('matches')->count(),
            DB::table('predictions')->count(), DB::table('user_achievements')->count(), $n
        ));

        return self::SUCCESS;
    }
}
