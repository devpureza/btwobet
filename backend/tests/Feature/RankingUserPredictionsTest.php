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

class RankingUserPredictionsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_approved_user_can_view_another_users_finished_predictions(): void
    {
        $target = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        $viewer = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        // Finished match with prediction
        $finishedMatch = $this->makeMatch('MEX', 'RSA', 'finished', 2, 0);
        Prediction::create([
            'user_id'    => $target->id,
            'match_id'   => $finishedMatch->id,
            'home_score' => 2,
            'away_score' => 0,
            'points'     => 2,
        ]);

        // Scheduled match with prediction — must NOT appear in response
        $scheduledMatch = $this->makeMatch('BRA', 'ARG', 'scheduled');
        Prediction::create([
            'user_id'    => $target->id,
            'match_id'   => $scheduledMatch->id,
            'home_score' => 1,
            'away_score' => 0,
            'points'     => 0,
        ]);

        Sanctum::actingAs($viewer);

        $response = $this->getJson("/api/ranking/{$target->id}/predictions");

        $response->assertOk();

        $data = $response->json('data');
        $this->assertCount(1, $data, 'Only finished-match predictions should be returned');

        $item = $data[0];
        $this->assertEquals($finishedMatch->id, $item['match_id']);
        $this->assertEquals(2, $item['prediction']['home_score']);
        $this->assertEquals(0, $item['prediction']['away_score']);
        $this->assertEquals(2, $item['result']['home_score']);
        $this->assertEquals(0, $item['result']['away_score']);
        $this->assertEquals(2, $item['points']);
        $this->assertEquals('Home MEX', $item['home_team']['name']);
        $this->assertNotEmpty($item['kickoff_at']);
        $this->assertEquals('Away RSA', $item['away_team']['name']);
        $this->assertNotNull($item['home_team']['flag_url']);
    }

    public function test_unapproved_user_cannot_view(): void
    {
        $unapprovedUser = User::factory()->create(['approval_status' => 'pending']);

        $finishedMatch = $this->makeMatch('MEX', 'RSA', 'finished', 2, 0);
        Prediction::create([
            'user_id'    => $unapprovedUser->id,
            'match_id'   => $finishedMatch->id,
            'home_score' => 2,
            'away_score' => 0,
            'points'     => 2,
        ]);

        Sanctum::actingAs($unapprovedUser);

        $response = $this->getJson("/api/ranking/{$unapprovedUser->id}/predictions");

        $response->assertStatus(403);
    }

    private function makeMatch(
        string $homeCode,
        string $awayCode,
        string $status = 'scheduled',
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): FootballMatch {
        $home = Team::create(['code' => $homeCode, 'name' => "Home {$homeCode}", 'group_name' => 'A', 'flag_url' => 'https://flagcdn.com/w80/br.png']);
        $away = Team::create(['code' => $awayCode, 'name' => "Away {$awayCode}", 'group_name' => 'A', 'flag_url' => 'https://flagcdn.com/w80/za.png']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at'   => Carbon::create(2026, 6, 11, 19, 0, 0, 'UTC'),
            'stage'        => 'group',
            'group_name'   => 'A',
            'venue'        => 'Test Arena',
            'status'       => $status,
            'home_score'   => $homeScore,
            'away_score'   => $awayScore,
        ]);
    }
}
