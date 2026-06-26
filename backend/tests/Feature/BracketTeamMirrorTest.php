<?php // backend/tests/Feature/BracketTeamMirrorTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\ScoreSync\FootballDataScoreProvider;
use App\Services\WorldCupScoreSyncService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BracketTeamMirrorTest extends TestCase
{
    use RefreshDatabase;

    public function test_fills_placeholder_with_real_team_but_not_when_locked(): void
    {
        $ph = Team::create(['code' => '2A', 'name' => '2A']);
        $bra = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        $jpn = Team::create(['code' => 'JPN', 'name' => 'Japan']);

        $open = FootballMatch::create(['external_id' => 500, 'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-06-29T17:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled', 'teams_locked' => false]);
        $locked = FootballMatch::create(['external_id' => 501, 'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-06-29T20:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled', 'teams_locked' => true]);

        $this->mock(FootballDataScoreProvider::class, function ($m) {
            $m->shouldReceive('fetchAll')->andReturn([
                ['external_id' => 500, 'stage' => 'knockout', 'home_name' => 'Brazil', 'away_name' => 'Japan', 'kickoff_at' => Carbon::parse('2026-06-29T17:00:00Z')],
                ['external_id' => 501, 'stage' => 'knockout', 'home_name' => 'Brazil', 'away_name' => 'Japan', 'kickoff_at' => Carbon::parse('2026-06-29T20:00:00Z')],
            ]);
        });

        $res = app(WorldCupScoreSyncService::class)->mirrorBracketTeams();

        $this->assertSame(1, $res['filled']);
        $open->refresh(); $locked->refresh();
        $this->assertSame($bra->id, $open->home_team_id);
        $this->assertSame($jpn->id, $open->away_team_id);
        $this->assertNotNull($open->teams_defined_at);
        $this->assertSame($ph->id, $locked->home_team_id); // lock respeitado
    }
}
