<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

class BolaoResetService
{
    /**
     * Apaga todos os palpites e zera placares oficiais dos jogos.
     *
     * @return array{predictions_deleted: int, matches_updated: int}
     */
    public function resetGameState(): array
    {
        return DB::transaction(function () {
            $predictionsDeleted = Prediction::query()->delete();

            $matchesUpdated = FootballMatch::query()->update([
                'status' => 'scheduled',
                'home_score' => null,
                'away_score' => null,
            ]);

            return [
                'predictions_deleted' => $predictionsDeleted,
                'matches_updated' => $matchesUpdated,
            ];
        });
    }

    /**
     * Apaga palpites, jogos e times. Mantém usuários e configurações.
     *
     * @return array{predictions_deleted: int, matches_deleted: int, teams_deleted: int}
     */
    public function resetBolaoTables(): array
    {
        return DB::transaction(function () {
            $predictionsDeleted = Prediction::query()->delete();
            $matchesDeleted = FootballMatch::query()->delete();
            $teamsDeleted = Team::query()->delete();

            return [
                'predictions_deleted' => $predictionsDeleted,
                'matches_deleted' => $matchesDeleted,
                'teams_deleted' => $teamsDeleted,
            ];
        });
    }

    /**
     * Recria o schema e roda os seeders (apaga usuários não seedados).
     */
    public function resetDatabase(bool $seed = true): void
    {
        Artisan::call('migrate:fresh', [
            '--force' => true,
            '--seed' => $seed,
        ]);
    }
}
