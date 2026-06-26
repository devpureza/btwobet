<?php // backend/tests/Feature/LinkExternalIdsTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\ScoreSync\FootballDataScoreProvider;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LinkExternalIdsTest extends TestCase
{
    use RefreshDatabase;

    public function test_links_by_kickoff_and_fixes_third_place_stage(): void
    {
        $ph = Team::create(['code' => 'L10', 'name' => 'L10']);
        $thirdPlace = FootballMatch::create([
            'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-07-18T21:00:00Z', 'stage' => 'group', 'status' => 'scheduled',
        ]);

        $this->mock(FootballDataScoreProvider::class, function ($m) {
            $m->shouldReceive('fetchAll')->andReturn([[
                'external_id' => 111222, 'stage' => 'knockout',
                'home_name' => null, 'away_name' => null,
                'kickoff_at' => Carbon::parse('2026-07-18T21:00:00Z'),
            ]]);
        });

        $this->artisan('worldcup:link-external-ids')->assertExitCode(0);

        $thirdPlace->refresh();
        $this->assertSame(111222, $thirdPlace->external_id);
        $this->assertSame('knockout', $thirdPlace->stage);
    }
}
