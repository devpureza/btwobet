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

class AdminPredictionsExportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_non_admin_cannot_export_predictions(): void
    {
        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);

        Sanctum::actingAs($user);

        $this->get('/api/admin/predictions/export')->assertForbidden();
    }

    public function test_admin_can_export_predictions_as_csv_with_header(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        $match = $this->makeMatch('AAA', 'BBB', 'finished', 1, 0);
        Prediction::create([
            'user_id' => $player->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 0,
        ]);

        Sanctum::actingAs($admin);

        $response = $this->get('/api/admin/predictions/export');
        $response->assertOk();

        $content = $response->streamedContent();
        $this->assertNotEmpty($content);

        $lines = preg_split("/\r\n|\n|\r/", trim($content));
        $this->assertIsArray($lines);
        $this->assertGreaterThanOrEqual(1, count($lines));

        // Remove BOM se presente.
        $header = ltrim((string) $lines[0], "\xEF\xBB\xBF");

        $this->assertSame(
            'prediction_id,user_id,user_name,user_email,match_id,match_kickoff_at,match_stage,match_group_name,match_status,home_team,away_team,prediction_home_score,prediction_away_score,match_home_score,match_away_score,points,created_at,updated_at',
            $header
        );
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
            'kickoff_at' => Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC'),
            'stage' => 'group',
            'group_name' => 'A',
            'venue' => 'Test Arena',
            'status' => $status,
            'home_score' => $homeScore,
            'away_score' => $awayScore,
        ]);
    }
}

