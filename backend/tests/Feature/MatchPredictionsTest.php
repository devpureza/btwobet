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

class MatchPredictionsTest extends TestCase
{
    use RefreshDatabase;

    private static int $teamSeq = 0;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
        Carbon::setTestNow(Carbon::create(2026, 6, 20, 16, 30, 0, 'UTC'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_returns_forbidden_before_two_hour_reveal_window(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->addHours(3),
            status: 'scheduled',
        );

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 0,
        ]);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/matches/{$match->id}/predictions")
            ->assertForbidden()
            ->assertJsonPath('message', 'Palpites dos participantes ainda não estão disponíveis.');
    }

    public function test_lists_all_predictions_within_two_hours_of_kickoff(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $ana = User::factory()->create([
            'name' => 'Ana',
            'approval_status' => User::STATUS_APPROVED,
            'avatar_url' => '/storage/avatars/ana.png',
        ]);
        $bruno = User::factory()->create([
            'name' => 'Bruno',
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $match = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->addHour(),
            status: 'scheduled',
        );

        Prediction::create([
            'user_id' => $ana->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 0,
        ]);
        Prediction::create([
            'user_id' => $bruno->id,
            'match_id' => $match->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/matches/{$match->id}/predictions")
            ->assertOk()
            ->assertJsonPath('match_id', $match->id)
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.user.name', 'Ana')
            ->assertJsonPath('data.0.user.avatar_url', '/storage/avatars/ana.png')
            ->assertJsonPath('data.0.home_score', 2)
            ->assertJsonPath('data.0.away_score', 1)
            ->assertJsonPath('data.0.points', null)
            ->assertJsonPath('data.1.user.name', 'Bruno')
            ->assertJsonPath('data.1.home_score', 0)
            ->assertJsonPath('data.1.away_score', 0);
    }

    public function test_lists_predictions_with_points_after_match_finishes(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->subDay(),
            status: 'finished',
            homeScore: 2,
            awayScore: 1,
        );

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/matches/{$match->id}/predictions")
            ->assertOk()
            ->assertJsonPath('data.0.points', 2);
    }

    public function test_lists_predictions_when_match_is_live(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->subMinutes(30),
            status: 'live',
            homeScore: 1,
            awayScore: 0,
        );

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($viewer);

        $this->getJson("/api/matches/{$match->id}/predictions")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_matches_index_exposes_community_predictions_flag(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $hidden = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->addHours(5),
            status: 'scheduled',
        );
        $visible = $this->makeMatch(
            kickoffAt: Carbon::now('UTC')->addHour(),
            status: 'scheduled',
        );

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/matches');

        $response->assertOk();

        $rows = collect($response->json('data'))->keyBy('id');
        $this->assertFalse($rows[$hidden->id]['community_predictions_available']);
        $this->assertTrue($rows[$visible->id]['community_predictions_available']);
    }

    private function makeMatch(
        Carbon $kickoffAt,
        string $status = 'scheduled',
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): FootballMatch {
        self::$teamSeq++;
        $n = self::$teamSeq;
        $homeCode = 'H'.str_pad((string) $n, 2, '0', STR_PAD_LEFT);
        $awayCode = 'A'.str_pad((string) $n, 2, '0', STR_PAD_LEFT);

        $home = Team::create(['code' => $homeCode, 'name' => 'Home', 'group_name' => 'A']);
        $away = Team::create(['code' => $awayCode, 'name' => 'Away', 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoffAt,
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => $status,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
        ]);
    }
}
