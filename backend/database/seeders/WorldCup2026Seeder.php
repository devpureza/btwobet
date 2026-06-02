<?php

namespace Database\Seeders;

use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class WorldCup2026Seeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'devpureza@gmail.com'],
            [
                'name' => 'Mateus',
                'password' => Hash::make('12345678'),
                'is_admin' => true,
                'approval_status' => User::STATUS_APPROVED,
            ],
        );

        // Seed mínimo para dev: evita ambiente "sem jogos" quando o import ainda não foi rodado.
        if (FootballMatch::query()->count() === 0) {
            $brazil = Team::firstOrCreate(
                ['code' => 'BRA'],
                ['name' => 'Brasil', 'group_name' => 'A', 'flag_url' => null],
            );
            $argentina = Team::firstOrCreate(
                ['code' => 'ARG'],
                ['name' => 'Argentina', 'group_name' => 'A', 'flag_url' => null],
            );

            FootballMatch::create([
                'home_team_id' => $brazil->id,
                'away_team_id' => $argentina->id,
                'kickoff_at' => Carbon::now('UTC')->addDays(1)->setTime(18, 0, 0),
                'stage' => 'group',
                'group_name' => 'A',
                'venue' => 'Demo Arena',
                'status' => 'scheduled',
                'home_score' => null,
                'away_score' => null,
            ]);
        }
    }
}
