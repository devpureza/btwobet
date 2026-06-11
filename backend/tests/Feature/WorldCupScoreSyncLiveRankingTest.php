<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\BolaoSettings;
use App\Services\RankingService;
use App\Services\ScoreSync\GloboEsporteScoreProvider;
use App\Services\WorldCupScoreSyncService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class WorldCupScoreSyncLiveRankingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_sync_updates_prediction_points_and_ranking_during_live_match(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 20, 19, 30, 0, 'UTC'));

        $home = Team::create(['code' => 'BRA', 'name' => 'Brasil', 'group_name' => 'A']);
        $away = Team::create(['code' => 'ARG', 'name' => 'Argentina', 'group_name' => 'A']);

        $kickoff = Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC');
        $match = FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoff,
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => 'scheduled',
            'home_score' => null,
            'away_score' => null,
        ]);

        $alice = User::factory()->create(['name' => 'Alice', 'approval_status' => User::STATUS_APPROVED]);
        $bob = User::factory()->create(['name' => 'Bob', 'approval_status' => User::STATUS_APPROVED]);

        Prediction::create([
            'user_id' => $alice->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);
        Prediction::create([
            'user_id' => $bob->id,
            'match_id' => $match->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 0,
        ]);

        $this->mockGloboGames([
            [
                'home_name' => 'Brasil',
                'away_name' => 'Argentina',
                'kickoff_at' => $kickoff,
                'home_score' => 1,
                'away_score' => 0,
            ],
        ]);

        app(WorldCupScoreSyncService::class)->syncFromGloboEsporte();

        $match->refresh();
        $this->assertSame('live', $match->status);
        $this->assertSame(1, $match->home_score);
        $this->assertSame(0, $match->away_score);

        $alicePrediction = Prediction::where('user_id', $alice->id)->where('match_id', $match->id)->first();
        $bobPrediction = Prediction::where('user_id', $bob->id)->where('match_id', $match->id)->first();
        $this->assertSame(2, $alicePrediction->points);
        $this->assertSame(0, $bobPrediction->points);

        Sanctum::actingAs($alice);
        $this->getJson('/api/ranking')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Alice')
            ->assertJsonPath('data.0.total_points', 2)
            ->assertJsonPath('data.1.name', 'Bob')
            ->assertJsonPath('data.1.total_points', 0);

        $this->mockGloboGames([
            [
                'home_name' => 'Brasil',
                'away_name' => 'Argentina',
                'kickoff_at' => $kickoff,
                'home_score' => 1,
                'away_score' => 1,
            ],
        ]);

        app(WorldCupScoreSyncService::class)->syncFromGloboEsporte();

        $alicePrediction->refresh();
        $bobPrediction->refresh();
        $this->assertSame(0, $alicePrediction->points);
        $this->assertSame(1, $bobPrediction->points);

        $ranking = app(RankingService::class)->getRanking();
        $this->assertSame(0, (int) $ranking->firstWhere('name', 'Alice')->total_points);
        $this->assertSame(1, (int) $ranking->firstWhere('name', 'Bob')->total_points);
    }

    public function test_sync_finalizes_match_after_105_minutes_and_recalculates_idempotently(): void
    {
        $home = Team::create(['code' => 'FRA', 'name' => 'França', 'group_name' => 'B']);
        $away = Team::create(['code' => 'GER', 'name' => 'Alemanha', 'group_name' => 'B']);

        $kickoff = Carbon::create(2026, 6, 20, 16, 0, 0, 'UTC');
        Carbon::setTestNow($kickoff->copy()->addMinutes(106));

        $match = FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoff,
            'stage' => 'group',
            'group_name' => 'B',
            'venue' => 'Test Arena',
            'status' => 'live',
            'home_score' => 2,
            'away_score' => 1,
        ]);

        $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);

        $this->mockGloboGames([
            [
                'home_name' => 'França',
                'away_name' => 'Alemanha',
                'kickoff_at' => $kickoff,
                'home_score' => 2,
                'away_score' => 1,
            ],
        ]);

        app(WorldCupScoreSyncService::class)->syncFromGloboEsporte();

        $match->refresh();
        $this->assertSame('finished', $match->status);
        $this->assertSame(2, Prediction::where('match_id', $match->id)->value('points'));
    }

    /**
     * @param list<array{home_name: string, away_name: string, kickoff_at: Carbon, home_score: int, away_score: int}> $games
     */
    private function mockGloboGames(array $games): void
    {
        $payload = array_map(fn (array $game) => array_merge($game, [
            'started' => true,
            'external_id' => null,
        ]), $games);

        $this->mock(GloboEsporteScoreProvider::class, function ($mock) use ($payload) {
            $mock->shouldReceive('fetch')->andReturn($payload);
        });
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        Mockery::close();
        parent::tearDown();
    }
}
