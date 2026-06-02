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

class AdminClearUserPredictionsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_admin_can_clear_predictions_for_specific_user(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        $m1 = $this->makeMatch('AAA', 'BBB', 'scheduled');
        $m2 = $this->makeMatch('CCC', 'DDD', 'finished', 1, 0);

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $m1->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 0,
        ]);
        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $m2->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 2,
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson("/api/admin/users/{$player->id}/predictions/clear", [
            'status' => 'scheduled',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.user_id', $player->id)
            ->assertJsonPath('data.deleted', 1)
            ->assertJsonPath('data.filters.status', 'scheduled');

        $this->assertDatabaseCount('predictions', 1);
        $this->assertDatabaseHas('predictions', ['user_id' => $player->id, 'match_id' => $m2->id]);
    }

    public function test_non_admin_cannot_clear_predictions(): void
    {
        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        Sanctum::actingAs($user);

        $this->postJson("/api/admin/users/{$player->id}/predictions/clear")
            ->assertForbidden();
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

