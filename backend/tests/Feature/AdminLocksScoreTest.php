<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminLocksScoreTest extends TestCase
{
    use RefreshDatabase;

    private function makeAdmin(): User
    {
        return User::factory()->create([
            'is_admin'        => true,
            'approval_status' => 'approved',
        ]);
    }

    private function makeMatch(): FootballMatch
    {
        $home = Team::create(['code' => 'BRA', 'name' => 'Brasil', 'group_name' => 'A']);
        $away = Team::create(['code' => 'ARG', 'name' => 'Argentina', 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at'   => Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC'),
            'stage'        => 'knockout',
            'status'       => 'scheduled',
            'home_score'   => null,
            'away_score'   => null,
            'score_locked' => false,
        ]);
    }

    public function test_update_result_to_finished_sets_score_locked_true(): void
    {
        $admin = $this->makeAdmin();
        $match = $this->makeMatch();

        Sanctum::actingAs($admin);

        $response = $this->patchJson("/api/admin/matches/{$match->id}/result", [
            'status'     => 'finished',
            'home_score' => 1,
            'away_score' => 1,
        ]);

        $response->assertStatus(200);
        $this->assertTrue($match->fresh()->score_locked);
    }

    public function test_update_result_to_live_sets_score_locked_true(): void
    {
        $admin = $this->makeAdmin();
        $match = $this->makeMatch();

        Sanctum::actingAs($admin);

        $response = $this->patchJson("/api/admin/matches/{$match->id}/result", [
            'status'     => 'live',
            'home_score' => 0,
            'away_score' => 0,
        ]);

        $response->assertStatus(200);
        $this->assertTrue($match->fresh()->score_locked);
    }

    public function test_update_result_to_scheduled_sets_score_locked_false(): void
    {
        $admin = $this->makeAdmin();
        $match = $this->makeMatch();

        // First lock it
        $match->score_locked = true;
        $match->save();

        Sanctum::actingAs($admin);

        $response = $this->patchJson("/api/admin/matches/{$match->id}/result", [
            'status' => 'scheduled',
        ]);

        $response->assertStatus(200);
        $this->assertFalse($match->fresh()->score_locked);
    }
}
