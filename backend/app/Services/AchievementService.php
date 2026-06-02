<?php

namespace App\Services;

use App\Models\Achievement;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\User;
use App\Models\UserAchievement;

class AchievementService
{
    public function __construct(private readonly AchievementEvaluator $evaluator) {}

    /**
     * Idempotent backfill: unlocks achievements the user already qualifies for
     * from historical predictions, finished matches, and ranking data.
     *
     * @return list<array{slug: string, name: string, tier: string}>
     */
    public function evaluateForUser(User $user): array
    {
        return $this->evaluateAndUnlock($user);
    }

    public function evaluateAndUnlock(
        User $user,
        ?Prediction $triggerPrediction = null,
        ?FootballMatch $contextMatch = null,
    ): array {
        $newlyUnlocked = [];

        foreach (Achievement::orderBy('sort_order')->get() as $achievement) {
            if ($this->isAlreadyUnlocked($user, $achievement)) {
                continue;
            }

            if (! $this->shouldUnlock($user, $achievement, $triggerPrediction, $contextMatch)) {
                continue;
            }

            UserAchievement::create([
                'user_id' => $user->id,
                'achievement_id' => $achievement->id,
                'unlocked_at' => now(),
            ]);

            $newlyUnlocked[] = [
                'slug' => $achievement->slug,
                'name' => $achievement->name,
                'tier' => $achievement->tier,
            ];
        }

        return $newlyUnlocked;
    }

    /**
     * @return array{catalog: list<array<string, mixed>>}
     */
    public function catalogForUser(User $user): array
    {
        $unlockedByAchievementId = UserAchievement::query()
            ->where('user_id', $user->id)
            ->get()
            ->keyBy('achievement_id');

        $catalog = Achievement::orderBy('sort_order')->get()->map(function (Achievement $achievement) use ($user, $unlockedByAchievementId) {
            $unlock = $unlockedByAchievementId->get($achievement->id);
            $progress = $achievement->is_trackable
                ? $this->evaluator->progress($user, $achievement)
                : null;

            return [
                'slug' => $achievement->slug,
                'name' => $achievement->name,
                'description' => $achievement->description,
                'tier' => $achievement->tier,
                'is_trackable' => $achievement->is_trackable,
                'unlocked' => $unlock !== null,
                'unlocked_at' => $unlock?->unlocked_at?->toIso8601String(),
                'progress' => $progress,
            ];
        })->all();

        return ['catalog' => $catalog];
    }

    public function evaluateUsersForFinishedMatch(FootballMatch $match): void
    {
        $userIds = Prediction::where('match_id', $match->id)->pluck('user_id')->unique();

        foreach ($userIds as $userId) {
            $user = User::find($userId);
            if ($user) {
                $this->evaluateAndUnlock($user, contextMatch: $match->fresh());
            }
        }

        $this->evaluateRankingForAllUsers();
    }

    public function evaluateRankingForAllUsers(): void
    {
        $ranking = app(RankingService::class)->getRanking();
        $scoredUsers = $ranking->filter(fn ($row) => (int) $row->scored_predictions >= 1)->count();

        foreach ($ranking as $index => $row) {
            $user = User::find($row->id);
            if ($user === null) {
                continue;
            }

            $position = $index + 1;
            $previousPosition = $user->last_ranking_position;

            $this->evaluator->clearRankingContext();
            $this->evaluator->setRankingContext(
                $position,
                $scoredUsers,
                (int) $row->scored_predictions,
            );

            if ($previousPosition !== null) {
                $this->evaluator->markRecuperacaoEligible((int) $previousPosition, $position);
            }

            $this->evaluator->updateRankingStreak($user, $position);
            $user->save();

            $this->evaluateAndUnlock($user->fresh());
        }
    }

    private function isAlreadyUnlocked(User $user, Achievement $achievement): bool
    {
        return UserAchievement::query()
            ->where('user_id', $user->id)
            ->where('achievement_id', $achievement->id)
            ->exists();
    }

    private function shouldUnlock(
        User $user,
        Achievement $achievement,
        ?Prediction $triggerPrediction,
        ?FootballMatch $contextMatch,
    ): bool {
        if ($achievement->slug === 'bem-vindo') {
            return true;
        }

        return $this->evaluator->isUnlocked($user, $achievement);
    }
}
