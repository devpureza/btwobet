<?php // backend/tests/Feature/AdminSetTeamsTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSetTeamsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_set_teams_and_locks(): void
    {
        $admin = User::factory()->create(['is_admin' => true, 'approval_status' => 'approved']);
        $ph = Team::create(['code' => 'W73', 'name' => 'W73']);
        $bra = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        $arg = Team::create(['code' => 'ARG', 'name' => 'Argentina']);
        $m = FootballMatch::create(['home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-07-09T20:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled']);

        $this->actingAs($admin)->patchJson("/api/admin/matches/{$m->id}", [
            'home_team_id' => $bra->id, 'away_team_id' => $arg->id,
        ])->assertOk();

        $m->refresh();
        $this->assertSame($bra->id, $m->home_team_id);
        $this->assertSame($arg->id, $m->away_team_id);
        $this->assertTrue($m->teams_locked);
        $this->assertNotNull($m->teams_defined_at);
    }
}
