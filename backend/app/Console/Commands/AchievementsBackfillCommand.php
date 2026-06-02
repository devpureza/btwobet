<?php

namespace App\Console\Commands;

use App\Models\Prediction;
use App\Models\User;
use App\Services\AchievementService;
use Illuminate\Console\Command;

class AchievementsBackfillCommand extends Command
{
    protected $signature = 'achievements:backfill
        {--user= : Limit to a single user id}
        {--dry-run : Report how many users would be processed without unlocking}';

    protected $description = 'Unlock achievements users already qualify for (safe, idempotent backfill)';

    public function handle(AchievementService $achievements): int
    {
        $userId = $this->option('user');
        $dryRun = (bool) $this->option('dry-run');

        $query = User::query()->whereIn('id', Prediction::query()->select('user_id')->distinct());

        if ($userId !== null && $userId !== '') {
            $query->whereKey((int) $userId);
        }

        $users = $query->orderBy('id')->get();

        if ($users->isEmpty()) {
            $this->info('Nenhum usuário com palpites para processar.');

            return self::SUCCESS;
        }

        if ($dryRun) {
            $this->info("Dry run: {$users->count()} usuário(s) seriam avaliados.");

            return self::SUCCESS;
        }

        $totalUnlocks = 0;

        foreach ($users as $user) {
            $unlocked = $achievements->evaluateForUser($user);
            $count = count($unlocked);
            $totalUnlocks += $count;

            if ($count > 0) {
                $slugs = implode(', ', array_column($unlocked, 'slug'));
                $this->line("User #{$user->id}: +{$count} ({$slugs})");
            }
        }

        $this->info("Concluído. {$users->count()} usuário(s), {$totalUnlocks} desbloqueio(s) novos.");

        return self::SUCCESS;
    }
}
