<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\User;
use App\Services\BolaoSettings;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AchievementApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_user_can_list_achievements_catalog(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/me/achievements');

        $response->assertOk()
            ->assertJsonCount(8, 'data.catalog')
            ->assertJsonPath('data.catalog.0.slug', 'first_prediction')
            ->assertJsonPath('data.catalog.0.unlocked', false);
    }

    public function test_prediction_unlocks_first_prediction_and_returns_in_response(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeOpenMatch();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/predictions', [
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
        ]);

        $response->assertCreated()
            ->assertJsonPath('new_achievements.0.slug', 'first_prediction');

        $this->assertDatabaseHas('user_achievements', [
            'user_id' => $user->id,
        ]);

        $list = $this->getJson('/api/me/achievements');
        $list->assertJsonPath('data.catalog.0.unlocked', true);
    }

    public function test_last_call_unlocks_when_prediction_within_one_hour(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $kickoff = Carbon::now('UTC')->addMinutes(45);
        $match = $this->makeOpenMatch($kickoff, stage: 'group');
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/predictions', [
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
        ]);

        $response->assertCreated();
        $slugs = collect($response->json('new_achievements'))->pluck('slug');
        $this->assertTrue($slugs->contains('first_prediction'));
        $this->assertTrue($slugs->contains('last_call'));
    }

    private function makeOpenMatch(?Carbon $kickoff = null, string $stage = 'group'): FootballMatch
    {
        $kickoff ??= Carbon::now('UTC')->addDay();
        $home = Team::create(['code' => 'HOM', 'name' => 'Home', 'group_name' => 'A']);
        $away = Team::create(['code' => 'AWY', 'name' => 'Away', 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoff,
            'stage' => $stage,
            'group_name' => $stage === 'group' ? 'A' : null,
            'venue' => 'Arena',
            'status' => 'scheduled',
        ]);
    }
}
