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

class AdminPredictionsHistoryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_admin_can_list_all_predictions_with_pagination(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch();

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 3,
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/predictions?per_page=10');

        $response->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.user.email', $player->email)
            ->assertJsonPath('data.0.prediction.home_score', 2)
            ->assertJsonPath('data.0.points', 3);
    }

    public function test_non_admin_cannot_access_predictions_history(): void
    {
        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/admin/predictions')->assertForbidden();
    }

    public function test_search_filters_by_user_name(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $alice = User::factory()->create([
            'name' => 'Alice Silva',
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $bob = User::factory()->create([
            'name' => 'Bob Costa',
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $matchAlice = $this->makeMatch('AAA', 'BBB');
        $matchBob = $this->makeMatch('CCC', 'DDD');

        Prediction::create([
            'user_id' => $alice->id,
            'match_id' => $matchAlice->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);
        Prediction::create([
            'user_id' => $bob->id,
            'match_id' => $matchBob->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($admin);

        $response = $this->getJson('/api/admin/predictions?q=alice');

        $response->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.user.name', 'Alice Silva');
    }

    private function makeMatch(string $homeCode = 'HOM', string $awayCode = 'AWY'): FootballMatch
    {
        $home = Team::create(['code' => $homeCode, 'name' => "Home {$homeCode}", 'group_name' => 'A']);
        $away = Team::create(['code' => $awayCode, 'name' => "Away {$awayCode}", 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC'),
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => 'scheduled',
        ]);
    }
}
