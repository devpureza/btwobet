<?php

namespace Tests\Unit;

use App\Models\Achievement;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use App\Services\AchievementEvaluator;
use App\Services\AchievementService;
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

    public function test_dez_palpites_unlocks_at_ten_predictions(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'dez-palpites')->firstOrFail();

        for ($i = 0; $i < 9; $i++) {
            Prediction::create([
                'user_id' => $user->id,
                'match_id' => $this->makeMatch("H{$i}", "A{$i}")->id,
                'home_score' => 1,
                'away_score' => 0,
                'points' => 0,
            ]);
        }

        $this->assertFalse($this->evaluator->isUnlocked($user->fresh(), $achievement));

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $this->makeMatch('H9', 'A9')->id,
            'home_score' => 0,
            'away_score' => 1,
            'points' => 0,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_sequencia_de_resultado_requires_five_consecutive_result_hits(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'sequencia-de-resultado')->firstOrFail();

        $dates = [
            '2026-06-10 15:00:00',
            '2026-06-11 15:00:00',
            '2026-06-12 15:00:00',
            '2026-06-13 15:00:00',
            '2026-06-14 15:00:00',
            '2026-06-15 15:00:00',
        ];

        foreach ($dates as $index => $date) {
            $match = $this->makeMatch("R{$index}H", "R{$index}A", 'finished', Carbon::parse($date, 'UTC'));
            Prediction::create([
                'user_id' => $user->id,
                'match_id' => $match->id,
                'home_score' => 1,
                'away_score' => 0,
                'points' => $index === 2 ? 0 : 1,
            ]);
        }

        $this->assertSame(3, $this->evaluator->bestResultStreak($user->fresh()));
        $this->assertFalse($this->evaluator->isUnlocked($user->fresh(), $achievement));

        Prediction::where('user_id', $user->id)->where('points', 0)->update(['points' => 1]);

        $this->assertGreaterThanOrEqual(5, $this->evaluator->bestResultStreak($user->fresh()));
        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_dupla_exata_requires_two_consecutive_exact_scores(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'dupla-exata')->firstOrFail();

        $m1 = $this->makeMatch('A', 'B', 'finished', Carbon::parse('2026-06-10 15:00:00', 'UTC'));
        $m2 = $this->makeMatch('C', 'D', 'finished', Carbon::parse('2026-06-11 15:00:00', 'UTC'));
        $m3 = $this->makeMatch('E', 'F', 'finished', Carbon::parse('2026-06-12 15:00:00', 'UTC'));

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $m1->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $m2->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 1,
        ]);
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $m3->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 2,
        ]);

        $this->assertFalse($this->evaluator->isUnlocked($user, $achievement));

        Prediction::where('user_id', $user->id)->where('match_id', $m2->id)->update(['points' => 2]);

        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_top_10_unlocks_with_ten_eligible_users(): void
    {
        $achievement = Achievement::where('slug', 'top-10')->firstOrFail();
        $match = $this->makeMatch('TOP', 'TEN', 'finished', Carbon::parse('2026-06-20 18:00:00', 'UTC'), 1, 0);

        $leader = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Prediction::create([
            'user_id' => $leader->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 2,
        ]);

        for ($i = 0; $i < 8; $i++) {
            $user = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
            Prediction::create([
                'user_id' => $user->id,
                'match_id' => $match->id,
                'home_score' => 0,
                'away_score' => 1,
                'points' => 0,
            ]);
        }

        $tenth = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);
        Prediction::create([
            'user_id' => $tenth->id,
            'match_id' => $match->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 1,
        ]);

        app(AchievementService::class)->evaluateRankingForAllUsers();

        $this->assertDatabaseHas('user_achievements', [
            'user_id' => $leader->id,
            'achievement_id' => $achievement->id,
        ]);
        $this->assertDatabaseHas('user_achievements', [
            'user_id' => $tenth->id,
            'achievement_id' => $achievement->id,
        ]);
    }

    public function test_bem_vindo_is_not_auto_unlocked(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'bem-vindo')->firstOrFail();

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $this->makeMatch('A', 'B')->id,
            'home_score' => 1,
            'away_score' => 0,
            'points' => 0,
        ]);

        $this->assertFalse($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_pontuador_unlocks_at_ten_points(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'pontuador')->firstOrFail();

        foreach (range(1, 8) as $i) {
            $match = $this->makeMatch("P{$i}H", "P{$i}A", 'finished', Carbon::parse("2026-06-{$i} 15:00:00", 'UTC'), 1, 0);
            Prediction::create([
                'user_id' => $user->id,
                'match_id' => $match->id,
                'home_score' => 1,
                'away_score' => 0,
                'points' => 1,
            ]);
        }

        $this->assertFalse($this->evaluator->isUnlocked($user, $achievement));

        $match = $this->makeMatch('P9H', 'P9A', 'finished', Carbon::parse('2026-06-09 15:00:00', 'UTC'), 2, 1);
        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 2,
            'away_score' => 1,
            'points' => 2,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
    }

    public function test_zerinho_requires_zero_zero_exact(): void
    {
        $user = User::factory()->create();
        $achievement = Achievement::where('slug', 'zerinho')->firstOrFail();
        $match = $this->makeMatch('H', 'A', 'finished', Carbon::parse('2026-06-10 15:00:00', 'UTC'), 0, 0);

        Prediction::create([
            'user_id' => $user->id,
            'match_id' => $match->id,
            'home_score' => 0,
            'away_score' => 0,
            'points' => 2,
        ]);

        $this->assertTrue($this->evaluator->isUnlocked($user, $achievement));
    }

    public function test_perfil_com_cara_requires_avatar(): void
    {
        $user = User::factory()->create(['avatar_url' => null]);
        $achievement = Achievement::where('slug', 'perfil-com-cara')->firstOrFail();

        $this->assertFalse($this->evaluator->isUnlocked($user, $achievement));

        $user->avatar_url = '/storage/avatars/test.jpg';
        $user->save();

        $this->assertTrue($this->evaluator->isUnlocked($user->fresh(), $achievement));
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
