<?php

namespace Tests\Feature;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\BolaoSettings;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HallOfWeekTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
        Cache::flush();
        Carbon::setTestNow(Carbon::create(2026, 6, 11, 15, 0, 0, 'UTC'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_approved_user_can_fetch_hall_of_week_with_seeded_highlights(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        $goldPlayer = User::factory()->create([
            'name' => 'Ana Ouro',
            'approval_status' => User::STATUS_APPROVED,
            'avatar_url' => '/storage/avatars/ana.png',
        ]);
        $exactPlayer = User::factory()->create([
            'name' => 'Bruno Exato',
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $shamePlayer = User::factory()->create([
            'name' => 'Diego Invertido',
            'approval_status' => User::STATUS_APPROVED,
        ]);

        $kickoff = Carbon::now('UTC')->startOfWeek(Carbon::MONDAY)->addDays(1)->setTime(20, 0);

        $finishedA = $this->makeMatch('BRA', 'ARG', 'finished', 2, 1, $kickoff);
        $finishedB = $this->makeMatch('FRA', 'GER', 'finished', 0, 3, $kickoff->copy()->addDay());
        $oldMatch = $this->makeMatch('OLD', 'WEE', 'finished', 1, 0, $kickoff->copy()->subWeeks(2));

        Prediction::create([
            'user_id' => $goldPlayer->id,
            'match_id' => $finishedA->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $goldPlayer->id,
            'match_id' => $finishedB->id,
            'home_score' => 1,
            'away_score' => 1,
            'points' => 1,
        ]);
        Prediction::create([
            'user_id' => $exactPlayer->id,
            'match_id' => $finishedB->id,
            'home_score' => 0,
            'away_score' => 3,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $shamePlayer->id,
            'match_id' => $finishedB->id,
            'home_score' => 4,
            'away_score' => 0,
            'points' => 0,
        ]);
        Prediction::create([
            'user_id' => $shamePlayer->id,
            'match_id' => $oldMatch->id,
            'home_score' => 5,
            'away_score' => 0,
            'points' => 0,
        ]);

        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/hall-of-week');

        $response->assertOk()
            ->assertJsonPath('period_label', 'Esta semana')
            ->assertJsonPath('fame.0.key', 'rodada_ouro')
            ->assertJsonPath('fame.0.display_name', 'Ana Ouro')
            ->assertJsonPath('fame.0.subtitle', '3 pts na semana')
            ->assertJsonPath('fame.1.key', 'placar_exato_semana')
            ->assertJsonPath('fame.1.display_name', 'Bruno Exato')
            ->assertJsonPath('shame.0.key', 'profecia_invertida')
            ->assertJsonPath('shame.0.display_name', 'Diego Invertido')
            ->assertJsonPath('shame.0.subtitle', 'Previu 4×0, saiu 0×3');
    }

    public function test_hall_of_week_returns_empty_lists_when_no_qualifying_data(): void
    {
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Sanctum::actingAs($viewer);

        $response = $this->getJson('/api/hall-of-week');

        $response->assertOk()
            ->assertJsonPath('fame', [])
            ->assertJsonPath('shame', []);
    }

    private function makeMatch(
        string $homeCode,
        string $awayCode,
        string $status,
        ?int $homeScore,
        ?int $awayScore,
        Carbon $kickoff,
    ): FootballMatch {
        $home = Team::create(['code' => $homeCode, 'name' => "Home {$homeCode}", 'group_name' => 'A']);
        $away = Team::create(['code' => $awayCode, 'name' => "Away {$awayCode}", 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoff,
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => $status,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
        ]);
    }
}
