<?php

namespace App\Services;

use App\Enums\AchievementSlug;
use App\Models\Achievement;
use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AchievementEvaluator
{
    /** @var Collection<int, string>|null */
    private static ?Collection $completedRoundDaysCache = null;

    public function isUnlocked(User $user, Achievement $achievement): bool
    {
        return match (AchievementSlug::tryFrom($achievement->slug)) {
            AchievementSlug::FirstPrediction => $this->hasAnyPrediction($user),
            AchievementSlug::ExactScore => $this->hasExactScore($user),
            AchievementSlug::PointsHatTrick => $this->pointsHatTrickStreak($user) >= 3,
            AchievementSlug::RoundGold => $this->hasRoundGold($user),
            AchievementSlug::ThreeDayStreak => $this->predictionDayStreak($user) >= 3,
            AchievementSlug::CenturyPoints => $this->totalPoints($user) >= 100,
            AchievementSlug::LastCall => $this->hasLastCall($user),
            AchievementSlug::FinalProphet => $this->hasFinalProphet($user),
            default => false,
        };
    }

    /**
     * @return array{current: int, target: int}|null
     */
    public function progress(User $user, Achievement $achievement): ?array
    {
        return match (AchievementSlug::tryFrom($achievement->slug)) {
            AchievementSlug::PointsHatTrick => [
                'current' => min(3, $this->pointsHatTrickStreak($user)),
                'target' => 3,
            ],
            AchievementSlug::ThreeDayStreak => [
                'current' => min(3, $this->predictionDayStreak($user)),
                'target' => 3,
            ],
            AchievementSlug::CenturyPoints => [
                'current' => min(100, $this->totalPoints($user)),
                'target' => 100,
            ],
            default => null,
        };
    }

    public function qualifiesLastCall(Prediction $prediction, FootballMatch $match): bool
    {
        if ($match->kickoff_at === null) {
            return false;
        }

        $kickoff = $match->kickoff_at->copy()->utc();
        $created = Carbon::parse($prediction->created_at ?? now())->utc();

        return $created->lt($kickoff) && $created->gte($kickoff->copy()->subHour());
    }

    private function hasAnyPrediction(User $user): bool
    {
        return Prediction::where('user_id', $user->id)->exists();
    }

    private function hasExactScore(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->where('points', 2)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->exists();
    }

    private function hasLastCall(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->with('match')
            ->get()
            ->contains(fn (Prediction $p) => $p->match && $this->qualifiesLastCall($p, $p->match));
    }

    private function totalPoints(User $user): int
    {
        return (int) Prediction::where('user_id', $user->id)->sum('points');
    }

    public function pointsHatTrickStreak(User $user): int
    {
        $predictions = Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->with('match')
            ->get()
            ->sortBy(fn (Prediction $p) => $p->match?->kickoff_at?->timestamp ?? PHP_INT_MAX)
            ->values();

        $best = 0;
        $current = 0;

        foreach ($predictions as $prediction) {
            if ($prediction->points > 0) {
                $current++;
                $best = max($best, $current);
            } else {
                $current = 0;
            }
        }

        return $best;
    }

    public function predictionDayStreak(User $user): int
    {
        $days = Prediction::query()
            ->where('user_id', $user->id)
            ->orderBy('created_at')
            ->pluck('created_at')
            ->map(fn ($dt) => Carbon::parse($dt)->utc()->toDateString())
            ->unique()
            ->sort()
            ->values()
            ->map(fn (string $d) => Carbon::parse($d.' 00:00:00', 'UTC'))
            ->values();

        if ($days->isEmpty()) {
            return 0;
        }

        $best = 1;
        $current = 1;

        for ($i = 1; $i < $days->count(); $i++) {
            $prev = $days[$i - 1];
            $cur = $days[$i];
            if ($prev->copy()->addDay()->isSameDay($cur)) {
                $current++;
                $best = max($best, $current);
            } else {
                $current = 1;
            }
        }

        return $best;
    }

    private function hasRoundGold(User $user): bool
    {
        $days = $this->completedRoundDays();

        foreach ($days as $day) {
            if ($this->userWonRoundOnDay($user, $day)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return Collection<int, string> Y-m-d UTC
     */
    private function completedRoundDays(): Collection
    {
        if (self::$completedRoundDaysCache !== null) {
            return self::$completedRoundDaysCache;
        }

        self::$completedRoundDaysCache = FootballMatch::query()
            ->get(['kickoff_at', 'status'])
            ->groupBy(fn (FootballMatch $m) => $m->kickoff_at?->utc()->toDateString())
            ->filter(fn ($group, $day) => $day !== null && $day !== '' && $group->isNotEmpty() && $group->every(fn (FootballMatch $m) => $m->status === 'finished'))
            ->keys()
            ->values();

        return self::$completedRoundDaysCache;
    }

    private function userWonRoundOnDay(User $user, string $day): bool
    {
        $start = Carbon::parse($day.' 00:00:00', 'UTC');
        $end = $start->copy()->endOfDay();

        $totals = DB::table('predictions')
            ->join('matches', 'predictions.match_id', '=', 'matches.id')
            ->where('matches.status', 'finished')
            ->whereBetween('matches.kickoff_at', [$start, $end])
            ->groupBy('predictions.user_id')
            ->selectRaw('predictions.user_id, COALESCE(SUM(predictions.points), 0) as round_points')
            ->pluck('round_points', 'user_id');

        if ($totals->isEmpty()) {
            return false;
        }

        $max = $totals->max();

        return (int) ($totals[$user->id] ?? 0) === (int) $max && (int) $max > 0;
    }

    private function hasFinalProphet(User $user): bool
    {
        $finalMatchIds = $this->cupFinalMatchIds();

        if ($finalMatchIds->isEmpty()) {
            return false;
        }

        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereIn('match_id', $finalMatchIds)
            ->where('points', 2)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->exists();
    }

    /**
     * @return Collection<int, int>
     */
    public function cupFinalMatchIds(): Collection
    {
        $explicit = FootballMatch::query()
            ->where('knockout_round', 'final')
            ->pluck('id');

        if ($explicit->isNotEmpty()) {
            return $explicit;
        }

        $latestKnockout = FootballMatch::query()
            ->where('stage', 'knockout')
            ->orderByDesc('kickoff_at')
            ->first();

        return $latestKnockout ? collect([$latestKnockout->id]) : collect();
    }

    public function isCupFinalMatch(FootballMatch $match): bool
    {
        if ($match->knockout_round === 'final') {
            return true;
        }

        return $this->cupFinalMatchIds()->contains($match->id);
    }
}
