<?php

namespace App\Console\Commands;

use App\Services\WorldCupScoreSyncService;
use Illuminate\Console\Command;

class SyncWorldCupScoresCommand extends Command
{
    protected $signature = 'worldcup:sync-scores';

    protected $description = 'Sincroniza placares da Copa a partir do ge.globo (JSON embutido na página)';

    public function handle(WorldCupScoreSyncService $sync): int
    {
        $this->info('Buscando jogos no ge.globo...');

        try {
            $stats = $sync->syncFromGloboEsporte();
        } catch (\Throwable $e) {
            $this->error($e->getMessage());
            $sync->recordFailedRun();

            return self::FAILURE;
        }

        $this->line("Jogos no GE: {$stats['found']}");
        $this->line("Casados no banco: {$stats['matched']}");
        $this->line("Atualizados: {$stats['updated']} (finalizados: {$stats['finished']})");

        if ($stats['unmatched'] !== []) {
            $this->warn('Sem correspondência ('.count($stats['unmatched']).'):');
            foreach (array_slice($stats['unmatched'], 0, 10) as $line) {
                $this->line("  - {$line}");
            }
            if (count($stats['unmatched']) > 10) {
                $this->line('  ...');
            }
        }

        return self::SUCCESS;
    }
}
