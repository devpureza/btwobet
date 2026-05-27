<?php

namespace Database\Seeders;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\RankingService;
use App\Services\ScoreCalculator;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class WorldCup2026Seeder extends Seeder
{
    public function run(): void
    {
        $teams = [
            ['code' => 'MEX', 'name' => 'México', 'group_name' => 'A'],
            ['code' => 'CAN', 'name' => 'Canadá', 'group_name' => 'A'],
            ['code' => 'USA', 'name' => 'Estados Unidos', 'group_name' => 'A'],
            ['code' => 'JAM', 'name' => 'Jamaica', 'group_name' => 'A'],
            ['code' => 'BRA', 'name' => 'Brasil', 'group_name' => 'B'],
            ['code' => 'ARG', 'name' => 'Argentina', 'group_name' => 'B'],
            ['code' => 'COL', 'name' => 'Colômbia', 'group_name' => 'B'],
            ['code' => 'CHI', 'name' => 'Chile', 'group_name' => 'B'],
            ['code' => 'FRA', 'name' => 'França', 'group_name' => 'C'],
            ['code' => 'GER', 'name' => 'Alemanha', 'group_name' => 'C'],
            ['code' => 'ESP', 'name' => 'Espanha', 'group_name' => 'C'],
            ['code' => 'POR', 'name' => 'Portugal', 'group_name' => 'C'],
            ['code' => 'ENG', 'name' => 'Inglaterra', 'group_name' => 'D'],
            ['code' => 'NED', 'name' => 'Holanda', 'group_name' => 'D'],
            ['code' => 'ITA', 'name' => 'Itália', 'group_name' => 'D'],
            ['code' => 'BEL', 'name' => 'Bélgica', 'group_name' => 'D'],
        ];

        $teamIds = [];
        foreach ($teams as $team) {
            $flagMap = [
                'MEX' => 'mx',
                'CAN' => 'ca',
                'USA' => 'us',
                'JAM' => 'jm',
                'BRA' => 'br',
                'ARG' => 'ar',
                'COL' => 'co',
                'CHI' => 'cl',
                'FRA' => 'fr',
                'GER' => 'de',
                'ESP' => 'es',
                'POR' => 'pt',
                'ENG' => 'gb-eng',
                'NED' => 'nl',
                'ITA' => 'it',
                'BEL' => 'be',
            ];

            $flag = $flagMap[$team['code']] ?? strtolower($team['code']);

            $record = Team::updateOrCreate(
                ['code' => $team['code']],
                [
                    'name' => $team['name'],
                    'group_name' => $team['group_name'],
                    'flag_url' => '/flags/'.$flag.'.png',
                ],
            );
            $teamIds[$team['code']] = $record->id;
        }

        $matches = [
            ['MEX', 'JAM', '2026-06-11 20:00:00', 'group', 'A', 'Estádio Azteca', 'finished', 2, 0],
            ['USA', 'CAN', '2026-06-12 18:00:00', 'group', 'A', 'MetLife Stadium', 'finished', 1, 1],
            ['BRA', 'COL', '2026-06-13 16:00:00', 'group', 'B', 'Hard Rock Stadium', 'finished', 3, 1],
            ['ARG', 'CHI', '2026-06-14 19:00:00', 'group', 'B', 'NRG Stadium', 'scheduled', null, null],
            ['FRA', 'GER', '2026-06-15 21:00:00', 'group', 'C', 'SoFi Stadium', 'scheduled', null, null],
            ['ESP', 'POR', '2026-06-16 17:00:00', 'group', 'C', 'Levi\'s Stadium', 'scheduled', null, null],
            ['ENG', 'NED', '2026-06-17 20:00:00', 'group', 'D', 'Lumen Field', 'scheduled', null, null],
            ['ITA', 'BEL', '2026-06-18 18:00:00', 'group', 'D', 'BMO Field', 'scheduled', null, null],
        ];

        $matchRecords = [];
        foreach ($matches as [$home, $away, $kickoff, $stage, $group, $venue, $status, $homeScore, $awayScore]) {
            $matchRecords[] = FootballMatch::updateOrCreate(
                [
                    'home_team_id' => $teamIds[$home],
                    'away_team_id' => $teamIds[$away],
                    'kickoff_at' => $kickoff,
                ],
                [
                    'stage' => $stage,
                    'group_name' => $group,
                    'venue' => $venue,
                    'status' => $status,
                    'home_score' => $homeScore,
                    'away_score' => $awayScore,
                ],
            );
        }

        $mateus = User::updateOrCreate(
            ['email' => 'mateus@bolao.test'],
            ['name' => 'Mateus', 'password' => Hash::make('senha1234'), 'is_admin' => true],
        );

        $igor = User::updateOrCreate(
            ['email' => 'igor@bolao.test'],
            ['name' => 'Igor Fraga', 'password' => Hash::make('senha1234')],
        );

        $demoPredictions = [
            [$mateus, 0, 2, 0],
            [$mateus, 1, 1, 1],
            [$mateus, 2, 2, 1],
            [$igor, 0, 1, 0],
            [$igor, 1, 0, 1],
            [$igor, 2, 3, 1],
        ];

        foreach ($demoPredictions as [$user, $matchIndex, $home, $away]) {
            Prediction::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'match_id' => $matchRecords[$matchIndex]->id,
                ],
                [
                    'home_score' => $home,
                    'away_score' => $away,
                    'points' => 0,
                ],
            );
        }

        $calculator = new ScoreCalculator();
        $rankingService = new RankingService();

        foreach ($matchRecords as $match) {
            if ($match->status === 'finished') {
                $rankingService->recalculateForMatch($match, $calculator);
            }
        }
    }
}
