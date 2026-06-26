<?php // backend/tests/Feature/PredictionWindowLateTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\PredictionWindow;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PredictionWindowLateTest extends TestCase
{
    use RefreshDatabase;

    public function test_late_defined_knockout_opens_until_3h_before(): void
    {
        Carbon::setTestNow('2026-07-04T10:00:00Z');
        $t = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        // kickoff em 5h; prazo normal (kickoff-24h) já passou, mas times definidos agora.
        $m = FootballMatch::create(['home_team_id' => $t->id, 'away_team_id' => $t->id,
            'kickoff_at' => '2026-07-04T15:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled',
            'teams_defined_at' => '2026-07-04T09:00:00Z']);

        $deadline = app(PredictionWindow::class)->deadlineForMatch($m);
        $this->assertEquals(Carbon::parse('2026-07-04T12:00:00Z'), $deadline); // kickoff - 3h
        Carbon::setTestNow();
    }
}
