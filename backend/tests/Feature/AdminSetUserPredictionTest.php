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

class AdminSetUserPredictionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_admin_can_create_prediction_for_user_on_live_match(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        // Jogo ao vivo, janela fechada, sem placar ainda — cenário real do Igor.
        $match = $this->makeMatch('XYZ', 'ZYX', 'live');

        Sanctum::actingAs($admin);

        $response = $this->postJson("/api/admin/users/{$player->id}/predictions/set", [
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.user_id', $player->id)
            ->assertJsonPath('data.match_id', $match->id)
            ->assertJsonPath('data.home_score', 2)
            ->assertJsonPath('data.away_score', 2);

        $this->assertDatabaseHas('predictions', [
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
        ]);
    }

    public function test_admin_set_overwrites_existing_prediction_and_recalculates_points(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        // Jogo com placar 2x2 em andamento -> recalc pontua sem disparar conquistas.
        $match = $this->makeMatch('AAA', 'BBB', 'live', 2, 2);

        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($admin);

        $response = $this->postJson("/api/admin/users/{$player->id}/predictions/set", [
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.home_score', 2)
            ->assertJsonPath('data.away_score', 2)
            ->assertJsonPath('data.points', 2); // cravou o placar => 2 pontos

        // Não duplica: unique(user_id, match_id) garante upsert.
        $this->assertDatabaseCount('predictions', 1);
        $this->assertDatabaseHas('predictions', [
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
            'points' => 2,
        ]);
    }

    public function test_non_admin_cannot_set_prediction(): void
    {
        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch('CCC', 'DDD', 'live');

        Sanctum::actingAs($user);

        $this->postJson("/api/admin/users/{$player->id}/predictions/set", [
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 2,
        ])->assertForbidden();

        $this->assertDatabaseCount('predictions', 0);
    }

    public function test_set_validates_score_range(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $match = $this->makeMatch('EEE', 'FFF', 'live');

        Sanctum::actingAs($admin);

        $this->postJson("/api/admin/users/{$player->id}/predictions/set", [
            'match_id' => $match->id,
            'home_score' => -1,
            'away_score' => 2,
        ])->assertStatus(422);
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
            'kickoff_at' => Carbon::create(2026, 6, 30, 17, 0, 0, 'UTC'),
            'stage' => 'knockout',
            'group_name' => null,
            'venue' => 'Test Arena',
            'status' => $status,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
        ]);
    }
}
