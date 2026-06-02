<?php

namespace Tests\Unit;

use App\Models\Achievement;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\AchievementEvaluator;
use App\Services\BolaoSettings;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AchievementEvaluatorTest extends TestCase
{
    use RefreshDatabase;

    private AchievementEvaluator $evaluator;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
        $this->evaluator = app(AchievementEvaluator::class);
    }

    public function test_points_hat_trick_requires_three_consecutive_scoring_matches(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'points_hat_trick')->firstOrFail();

        $m1 = $this->makeMatch('A', 'B', 'finished', Carbon::parse('2026-06-10 15:00:00', 'UTC'));
        $m2 = $this->makeMatch('C', 'D', 'finished', Carbon::parse('2026-06-11 15:00:00', 'UTC'));
        $m3 = $this->makeMatch('E', 'F', 'finished', Carbon::parse('2026-06-12 15:00:00', 'UTC'));

        foreach ([[$m1, 1], [$m2, 0], [$m3, 1]] as [$match, $points]) {
            Prediction::create([
                'user_id' => $user->id,
                'match_id' => $match->id,
                'home_score' => 1,
                'away_score' => 0,
                'points' => $points,
            ]);
        }

        $this->assertSame(1, $this->evaluator->pointsHatTrickStreak($user));
        $this->assertFalse($this->evaluator->isUnlocked($user, $achievement));

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $this->makeMatch('G', 'H', 'finished', Carbon::parse('2026-06-13 15:00:00', 'UTC'))->id,
            'home_score' => 2,
            'away_score' => 2,
            'points' => 2,
        ]);

        Prediction::where('user_id', $user->id)->where('match_id', $m2->id)->update(['points' => 1]);

        $this->assertGreaterThanOrEqual(3, $this->evaluator->pointsHatTrickStreak($user->fresh()));
        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_three_day_streak_counts_consecutive_utc_days(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'three_day_streak')->firstOrFail();
        $match = $this->makeMatch('A', 'B');

        Carbon::setTestNow(Carbon::parse('2026-06-01 12:00:00', 'UTC'));
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        Carbon::setTestNow(Carbon::parse('2026-06-02 12:00:00', 'UTC'));
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $this->makeMatch('C', 'D')->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 0,
        ]);

        $this->assertSame(2, $this->evaluator->predictionDayStreak($user->fresh()));
        $this->assertFalse($this->evaluator->isUnlocked($user->fresh(), $achievement));

        Carbon::setTestNow(Carbon::parse('2026-06-03 12:00:00', 'UTC'));
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $this->makeMatch('E', 'F')->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 0,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));

        Carbon::setTestNow();
    }

    public function test_last_call_within_one_hour_before_kickoff(): void
    {
        $kickoff = Carbon::parse('2026-07-01 20:00:00', 'UTC');
        $match = $this->makeMatch('A', 'B', 'scheduled', $kickoff);
        $user = User::factory()->create();
        $prediction = Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 1,
            'points' => 0,
        ]);
        $prediction->forceFill([
            'created_at' => $kickoff->copy()->subMinutes(30),
            'updated_at' => $kickoff->copy()->subMinutes(30),
        ])->saveQuietly();

        $this->assertTrue($this->evaluator->qualifiesLastCall($prediction->fresh(), $match));

        $prediction->forceFill(['created_at' => $kickoff->copy()->subHours(2)])->saveQuietly();
        $this->assertFalse($this->evaluator->qualifiesLastCall($prediction->fresh(), $match));
    }

    public function test_final_prophet_requires_exact_score_on_final_match(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'final_prophet')->firstOrFail();

        $final = $this->makeMatch('BRA', 'ARG', 'finished', Carbon::parse('2026-07-19 20:00:00', 'UTC'), 2, 1);
        $final->update(['stage' => 'knockout', 'knockout_round' => 'final']);

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $final->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user, $achievement));
    }

    public function test_round_gold_when_user_tops_completed_day(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $achievement = Achievement::where('slug', 'round_gold')->firstOrFail();

        $day = Carbon::parse('2026-06-15 18:00:00', 'UTC');
        $m1 = $this->makeMatch('A', 'B', 'finished', $day, 1, 0);
        $m2 = $this->makeMatch('C', 'D', 'finished', $day->copy()->addHours(3), 0, 0);

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $m1->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $m2->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $other->id,
            'match_id' => $m1->id,
            'home_score' => 0,
            'away_score' => 1,
            'points' => 0,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user, $achievement));
        $this->assertFalse($this->evaluator->isUnlocked($other, $achievement));
    }

    private function makeMatch(
        string $homeCode,
        string $awayCode,
        string $status = 'scheduled',
        ?Carbon $kickoff = null,
        ?int $homeScore = null,
        ?int $awayScore = null,
    ): FootballMatch {
        $kickoff ??= Carbon::parse('2026-06-20 18:00:00', 'UTC');
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
