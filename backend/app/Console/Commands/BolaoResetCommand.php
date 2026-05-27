<?php

namespace App\Console\Commands;

use App\Services\BolaoResetService;
use Illuminate\Console\Command;

class BolaoResetCommand extends Command
{
    protected $signature = 'bolao:reset
        {scope=game : game|bolao|database — limpar palpites/placares, apagar jogos/times, ou migrate:fresh}
        {--force : Obrigatório em produção e para scope=database}';

    protected $description = 'Limpa palpites, pontuações e/ou dados do bolão; opcionalmente recria o banco';

    public function handle(BolaoResetService $reset): int
    {
        $scope = strtolower((string) $this->argument('scope'));

        if (! in_array($scope, ['game', 'bolao', 'database'], true)) {
            $this->error('Scope inválido. Use: game, bolao ou database.');

            return self::FAILURE;
        }

        if ($this->laravel->environment('production') && ! $this->option('force')) {
            $this->error('Em produção, use --force para confirmar.');

            return self::FAILURE;
        }

        if ($scope === 'database' && ! $this->option('force')) {
            $this->error('Scope database exige --force (migrate:fresh apaga tudo).');

            return self::FAILURE;
        }

        if (! $this->confirmAction($scope)) {
            $this->warn('Operação cancelada.');

            return self::SUCCESS;
        }

        return match ($scope) {
            'game' => $this->runGameReset($reset),
            'bolao' => $this->runBolaoReset($reset),
            'database' => $this->runDatabaseReset($reset),
        };
    }

    private function confirmAction(string $scope): bool
    {
        $messages = [
            'game' => 'Apagar TODOS os palpites e zerar placares/pontuações dos jogos?',
            'bolao' => 'Apagar palpites, jogos e times (usuários permanecem)?',
            'database' => 'Executar migrate:fresh --seed (recria o banco inteiro)?',
        ];

        return $this->confirm($messages[$scope], false);
    }

    private function runGameReset(BolaoResetService $reset): int
    {
        $stats = $reset->resetGameState();
        $this->info(sprintf(
            'Palpites removidos: %d. Jogos reabertos: %d.',
            $stats['predictions_deleted'],
            $stats['matches_updated'],
        ));

        return self::SUCCESS;
    }

    private function runBolaoReset(BolaoResetService $reset): int
    {
        $stats = $reset->resetBolaoTables();
        $this->info(sprintf(
            'Palpites: %d | Jogos: %d | Times: %d removidos.',
            $stats['predictions_deleted'],
            $stats['matches_deleted'],
            $stats['teams_deleted'],
        ));

        return self::SUCCESS;
    }

    private function runDatabaseReset(BolaoResetService $reset): int
    {
        $this->warn('Rodando migrate:fresh --seed...');
        $reset->resetDatabase(seed: true);
        $this->info('Banco recriado e seed aplicado.');

        return self::SUCCESS;
    }
}
