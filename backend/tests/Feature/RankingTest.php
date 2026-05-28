<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\BolaoSettings;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RankingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_approved_user_can_list_ranking_with_prediction_stats(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $player = User::factory()->create([
            'name' => 'João Palpiteiro',
            'approval_status' => User::STATUS_APPROVED,
        ]);

        $finished = $this->makeMatch('FIN', 'ISH', 'finished', 2, 1);
        $scheduled = $this->makeMatch('SCH', 'EDU', 'scheduled');

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $finished->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $scheduled->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/ranking');

        $response->assertOk()
            ->assertJsonPath('data.0.name', 'João Palpiteiro')
            ->assertJsonPath('data.0.total_points', 2)
            ->assertJsonPath('data.0.total_predictions', 2)
            ->assertJsonPath('data.0.scored_predictions', 1)
            ->assertJsonPath('data.0.exact_hits', 1)
            ->assertJsonPath('data.0.result_hits', 1)
            ->assertJsonPath('data.0.exact_hit_percent', 100)
            ->assertJsonPath('data.0.result_hit_percent', 100);
    }

    private function makeMatch(
        string $homeCode,
        string $awayCode,
        string $status = 'scheduled',
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): FootballMatch {
        $home = Team::create(['code' => $homeCode, 'name' => "Home {$homeCode}", 'group_name' => 'A']);
        $away = Team::create(['code' => $awayCode, 'name' => "Away {$awayCode}", 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC'),
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => $status,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
        ]);
    }
}
