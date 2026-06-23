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

class AchievementApiTest extends TestCase
{
    use RefreshDatabase;

    private static int $teamSeq = 0;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
        Carbon::setTestNow(Carbon::create(2026, 6, 1, 12, 0, 0, 'UTC'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow(null);
        parent::tearDown();
    }

    public function test_user_can_list_achievements_catalog(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/me/achievements');

        $response->assertOk()
            ->assertJsonCount(33, 'data.catalog')
            ->assertJsonPath('data.catalog.0.slug', 'primeiro-palpite')
            ->assertJsonPath('data.catalog.0.unlocked', false);
    }

    public function test_catalog_fetch_unlocks_existing_prediction_retroactively(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeOpenMatch();
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        $this->assertDatabaseMissing('user_achievements', ['user_id' => $user->id]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/me/achievements');

        $response->assertOk()
            ->assertJsonPath('data.catalog.0.slug', 'primeiro-palpite')
            ->assertJsonPath('data.catalog.0.unlocked', true)
            ->assertJsonPath('data.newly_unlocked.0.slug', 'primeiro-palpite');

        $this->assertDatabaseHas('user_achievements', ['user_id' => $user->id]);
    }

    public function test_prediction_unlocks_primeiro_palpite_and_returns_in_response(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeOpenMatch();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/predictions', [
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
        ]);

        $response->assertCreated();
        $slugs = collect($response->json('new_achievements'))->pluck('slug');
        $this->assertTrue($slugs->contains('primeiro-palpite'));

        $this->assertDatabaseHas('user_achievements', [
            'user_id' => $user->id,
        ]);

        $list = $this->getJson('/api/me/achievements');
        $list->assertJsonPath('data.catalog.0.unlocked', true);
    }

    public function test_em_campo_progress_after_three_predictions(): void
    {
        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Sanctum::actingAs($user);

        foreach (range(1, 3) as $i) {
            $match = $this->makeOpenMatch(Carbon::now('UTC')->addDays($i));
            $this->postJson('/api/predictions', [
                'match_id' => $match->id,
                'home_score' => 1,
                'away_score' => 0,
            ])->assertCreated();
        }

        $list = $this->getJson('/api/me/achievements');
        $emCampo = collect($list->json('data.catalog'))->firstWhere('slug', 'em-campo');

        $this->assertNotNull($emCampo);
        $this->assertSame(3, $emCampo['progress']['current']);
        $this->assertSame(5, $emCampo['progress']['target']);
    }

    private function makeOpenMatch(?Carbon $kickoff = null, string $stage = 'group'): FootballMatch
    {
        $kickoff ??= Carbon::now('UTC')->addDay();
        self::$teamSeq++;
        $homeCode = strtoupper(substr(base_convert((string) self::$teamSeq, 10, 36), 0, 3));
        $awayCode = strtoupper(substr(base_convert((string) (self::$teamSeq + 500), 10, 36), 0, 3));
        $home = Team::create(['code' => $homeCode, 'name' => 'Home', 'group_name' => 'A']);
        $away = Team::create(['code' => $awayCode, 'name' => 'Away', 'group_name' => 'A']);

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
