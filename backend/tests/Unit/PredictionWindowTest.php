<?php

namespace Tests\Unit;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Setting;
use App\Models\Team;
use App\Services\BolaoSettings;
use App\Services\PredictionWindow;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PredictionWindowTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_group_match_closes_after_group_deadline(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 12, 0, 0, 0, 'America/Sao_Paulo'));

        Setting::where('key', BolaoSettings::KEY_GROUP_DEADLINE)->update([
            'value' => Carbon::create(2026, 6, 11, 23, 59, 59, 'America/Sao_Paulo')->toIso8601String(),
        ]);
        cache()->forget('bolao.settings.all');

        $match = $this->makeMatch(stage: 'group', kickoff: Carbon::create(2026, 6, 15, 18, 0, 0, 'UTC'));

        $access = app(PredictionWindow::class)->evaluate($match, null);

        $this->assertFalse($access['can_submit']);
        $this->assertStringContainsString('grupos', strtolower($access['reason']));
    }

    public function test_knockout_closes_24h_before_kickoff(): void
    {
        $kickoff = Carbon::create(2026, 7, 1, 18, 0, 0, 'UTC');
        Carbon::setTestNow($kickoff->copy()->subHours(23));

        $match = $this->makeMatch(stage: 'knockout', kickoff: $kickoff);

        $access = app(PredictionWindow::class)->evaluate($match, null);

        $this->assertFalse($access['can_submit']);
    }

    public function test_existing_prediction_cannot_be_changed(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 1, 12, 0, 0, 'UTC'));

        $match = $this->makeMatch(stage: 'group', kickoff: Carbon::create(2026, 6, 20, 18, 0, 0, 'UTC'));
        $prediction = new Prediction(['home_score' => 1, 'away_score' => 0]);

        $access = app(PredictionWindow::class)->evaluate($match, $prediction);

        $this->assertFalse($access['can_submit']);
        $this->assertStringContainsString('alterar', strtolower($access['reason']));
    }

    private function makeMatch(string $stage, Carbon $kickoff): FootballMatch
    {
        $home = Team::create(['code' => 'AAA', 'name' => 'Home', 'group_name' => 'A']);
        $away = Team::create(['code' => 'BBB', 'name' => 'Away', 'group_name' => 'A']);

        return FootballMatch::create([
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'kickoff_at' => $kickoff,
            'stage' => $stage,
            'group_name' => $stage === 'group' ? 'A' : null,
            'venue' => 'Test',
            'status' => 'scheduled',
        ]);
    }
}
