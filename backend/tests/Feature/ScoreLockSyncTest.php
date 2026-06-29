<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\BolaoSettings;
use App\Services\ScoreSync\FootballDataScoreProvider;
use App\Services\WorldCupScoreSyncService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;

class ScoreLockSyncTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_sync_does_not_overwrite_score_locked_match(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 20, 21, 0, 0, 'UTC'));

        $home = Team::create(['code' => 'BRA', 'name' => 'Brasil', 'group_name' => 'A']);
        $away = Team::create(['code' => 'ARG', 'name' => 'Argentina', 'group_name' => 'A']);

        $kickoff = Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC');

        $lockedMatch = FootballMatch::create([
            'home_team_id'  => $home->id,
            'away_team_id'  => $away->id,
            'kickoff_at'    => $kickoff,
            'stage'         => 'knockout',
            'status'        => 'finished',
            'home_score'    => 1,
            'away_score'    => 1,
            'score_locked'  => true,
            'external_id'   => 999001,
        ]);

        // Mock provider: returns same teams + kickoff but DIFFERENT score (2-1)
        $mock = Mockery::mock(FootballDataScoreProvider::class);
        $mock->shouldReceive('fetch')->andReturn([
            [
                'home_name'  => 'Brasil',
                'away_name'  => 'Argentina',
                'kickoff_at' => $kickoff->copy(),
                'home_score' => 2,
                'away_score' => 1,
                'started'    => true,
                'finished'   => true,
                'external_id' => 999001,
            ],
        ]);
        $mock->shouldReceive('fetchAll')->andReturn([]);
        $this->app->instance(FootballDataScoreProvider::class, $mock);

        app(WorldCupScoreSyncService::class)->syncFromGloboEsporte();

        $lockedMatch->refresh();
        $this->assertEquals(1, $lockedMatch->home_score, 'Locked match home_score must not change');
        $this->assertEquals(1, $lockedMatch->away_score, 'Locked match away_score must not change');
    }

    public function test_sync_does_overwrite_unlocked_match(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 20, 21, 0, 0, 'UTC'));

        $home = Team::create(['code' => 'FRA', 'name' => 'France', 'group_name' => 'B']);
        $away = Team::create(['code' => 'ENG', 'name' => 'England', 'group_name' => 'B']);

        $kickoff = Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC');

        $unlockedMatch = FootballMatch::create([
            'home_team_id'  => $home->id,
            'away_team_id'  => $away->id,
            'kickoff_at'    => $kickoff,
            'stage'         => 'knockout',
            'status'        => 'finished',
            'home_score'    => 1,
            'away_score'    => 1,
            'score_locked'  => false,
            'external_id'   => 999002,
        ]);

        $mock = Mockery::mock(FootballDataScoreProvider::class);
        $mock->shouldReceive('fetch')->andReturn([
            [
                'home_name'  => 'France',
                'away_name'  => 'England',
                'kickoff_at' => $kickoff->copy(),
                'home_score' => 2,
                'away_score' => 1,
                'started'    => true,
                'finished'   => true,
                'external_id' => 999002,
            ],
        ]);
        $mock->shouldReceive('fetchAll')->andReturn([]);
        $this->app->instance(FootballDataScoreProvider::class, $mock);

        app(WorldCupScoreSyncService::class)->syncFromGloboEsporte();

        $unlockedMatch->refresh();
        $this->assertEquals(2, $unlockedMatch->home_score, 'Unlocked match home_score MUST be updated');
        $this->assertEquals(1, $unlockedMatch->away_score, 'Unlocked match away_score MUST be updated');
    }
}
