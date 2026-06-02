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
    /** @var array<string, mixed> */
    private array $rankingContext = [];

    public function setRankingContext(int $position, int $scoredUsersAtLeastOne, int $scoredPredictions): void
    {
        $this->rankingContext = [
            'position' => $position,
            'scored_users' => $scoredUsersAtLeastOne,
            'scored_predictions' => $scoredPredictions,
        ];
    }

    public function clearRankingContext(): void
    {
        $this->rankingContext = [];
    }

    public function isUnlocked(User $user, Achievement $achievement): bool
    {
        return match (AchievementSlug::tryFrom($achievement->slug)) {
            AchievementSlug::PrimeiroPalpite => $this->predictionCount($user) >= 1,
            AchievementSlug::EmCampo => $this->predictionCount($user) >= 5,
            AchievementSlug::PlacarNaMosca => $this->exactScoreCount($user) >= 1,
            AchievementSlug::TrioPerfeito => $this->exactScoreCount($user) >= 3,
            AchievementSlug::Pontuador => $this->totalPoints($user) >= 10,
            AchievementSlug::NoTopo => $this->qualifiesNoTopo(),
            AchievementSlug::Podio => $this->qualifiesPodio(),
            AchievementSlug::PresencaConfirmada => $this->distinctKickoffDays($user) >= 3,
            AchievementSlug::BemVindo => false,
            AchievementSlug::PerfilComCara => $this->hasAvatar($user),
            AchievementSlug::DezPalpites => $this->predictionCount($user) >= 10,
            AchievementSlug::MeiaCenturia => $this->predictionCount($user) >= 50,
            AchievementSlug::Maratonista => $this->distinctKickoffDays($user) >= 10,
            AchievementSlug::FaseGruposFirme => $this->qualifiesFaseGruposFirme($user),
            AchievementSlug::MataMataChegou => $this->hasKnockoutPrediction($user),
            AchievementSlug::ArtilheiroDeAcertos => $this->exactScoreCount($user) >= 10,
            AchievementSlug::SequenciaDeResultado => $this->bestResultStreak($user) >= 5,
            AchievementSlug::DuplaExata => $this->hasConsecutiveExactScores($user, 2),
            AchievementSlug::EmpateCerteiro => $this->hasDrawPredictionHit($user),
            AchievementSlug::Zerinho => $this->hasZeroZeroExact($user),
            AchievementSlug::GoleadaPrevista => $this->hasHighScoringExact($user),
            AchievementSlug::Top10 => $this->qualifiesTop10(),
            AchievementSlug::ViceCampeao => $this->qualifiesViceCampeao(),
            AchievementSlug::CampeaoDoBolao => $this->qualifiesCampeaoDoBolao(),
            AchievementSlug::Recuperacao => (bool) ($this->rankingContext['recuperacao'] ?? false),
            AchievementSlug::SemanaAtiva => $this->bestPredictionDayStreak($user) >= 7,
            AchievementSlug::SemMissNoFds => $this->hasCompleteWeekend($user),
            AchievementSlug::EstreiaDaCopa => $this->hasOpeningMatchPrediction($user),
            AchievementSlug::JogoDecisivo => $this->hasDecisiveMatchPrediction($user),
            AchievementSlug::GrandeFinal => $this->hasFinalMatchPrediction($user),
            AchievementSlug::UnderdogDoDia => $this->hasUnderdogWin($user),
            AchievementSlug::Oraculo => $this->exactScoreCount($user) >= 15,
            AchievementSlug::InvictoNoTopo => (int) ($user->ranking_first_streak ?? 0) >= 5,
            default => false,
        };
    }

    /**
     * @return array{current: int, target: int}|null
     */
    public function progress(User $user, Achievement $achievement): ?array
    {
        return match (AchievementSlug::tryFrom($achievement->slug)) {
            AchievementSlug::EmCampo => $this->progressValue($this->predictionCount($user), 5),
            AchievementSlug::TrioPerfeito => $this->progressValue($this->exactScoreCount($user), 3),
            AchievementSlug::Pontuador => $this->progressValue($this->totalPoints($user), 10),
            AchievementSlug::PresencaConfirmada => $this->progressValue($this->distinctKickoffDays($user), 3),
            AchievementSlug::DezPalpites => $this->progressValue($this->predictionCount($user), 10),
            AchievementSlug::MeiaCenturia => $this->progressValue($this->predictionCount($user), 50),
            AchievementSlug::Maratonista => $this->progressValue($this->distinctKickoffDays($user), 10),
            AchievementSlug::FaseGruposFirme => $this->faseGruposFirmeProgress($user),
            AchievementSlug::ArtilheiroDeAcertos => $this->progressValue($this->exactScoreCount($user), 10),
            AchievementSlug::SequenciaDeResultado => $this->progressValue($this->bestResultStreak($user), 5),
            AchievementSlug::SemanaAtiva => $this->progressValue($this->bestPredictionDayStreak($user), 7),
            AchievementSlug::Oraculo => $this->progressValue($this->exactScoreCount($user), 15),
            AchievementSlug::InvictoNoTopo => $this->progressValue((int) ($user->ranking_first_streak ?? 0), 5),
            default => null,
        };
    }

    public function markRecuperacaoEligible(int $previousPosition, int $currentPosition): void
    {
        if ($previousPosition > 0 && ($previousPosition - $currentPosition) >= 5) {
            $this->rankingContext['recuperacao'] = true;
        }
    }

    public function updateRankingStreak(User $user, int $position): void
    {
        if ($position === 1) {
            $user->ranking_first_streak = (int) ($user->ranking_first_streak ?? 0) + 1;
        } else {
            $user->ranking_first_streak = 0;
        }

        $user->last_ranking_position = $position;
    }

    private function progressValue(int $current, int $target): array
    {
        return [
            'current' => min($target, $current),
            'target' => $target,
        ];
    }

    private function predictionCount(User $user): int
    {
        return Prediction::where('user_id', $user->id)->count();
    }

    private function exactScoreCount(User $user): int
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->where('points', 2)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->count();
    }

    private function totalPoints(User $user): int
    {
        return (int) Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->sum('points');
    }

    private function hasAvatar(User $user): bool
    {
        return filled($user->avatar_url);
    }

    private function distinctKickoffDays(User $user): int
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->with('match')
            ->get()
            ->map(fn (Prediction $p) => $p->match?->kickoff_at?->utc()->toDateString())
            ->filter()
            ->unique()
            ->count();
    }

    /**
     * @return Collection<int, Prediction>
     */
    private function finishedPredictionsOrdered(User $user): Collection
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q->where('status', 'finished'))
            ->with('match')
            ->get()
            ->sortBy(fn (Prediction $p) => $p->match?->kickoff_at?->timestamp ?? PHP_INT_MAX)
            ->values();
    }

    public function bestResultStreak(User $user): int
    {
        $best = 0;
        $current = 0;

        foreach ($this->finishedPredictionsOrdered($user) as $prediction) {
            if ($prediction->points >= 1) {
                $current++;
                $best = max($best, $current);
            } else {
                $current = 0;
            }
        }

        return $best;
    }

    private function hasConsecutiveExactScores(User $user, int $required): bool
    {
        $current = 0;

        foreach ($this->finishedPredictionsOrdered($user) as $prediction) {
            if ($prediction->points === 2) {
                $current++;
                if ($current >= $required) {
                    return true;
                }
            } else {
                $current = 0;
            }
        }

        return false;
    }

    private function hasDrawPredictionHit(User $user): bool
    {
        return $this->finishedPredictionsOrdered($user)->contains(function (Prediction $prediction) {
            $match = $prediction->match;
            if ($match === null || $match->home_score === null || $match->away_score === null) {
                return false;
            }

            return $match->home_score === $match->away_score
                && $prediction->home_score === $prediction->away_score
                && $prediction->points >= 1;
        });
    }

    private function hasZeroZeroExact(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->where('home_score', 0)
            ->where('away_score', 0)
            ->where('points', 2)
            ->whereHas('match', fn ($q) => $q
                ->where('status', 'finished')
                ->where('home_score', 0)
                ->where('away_score', 0))
            ->exists();
    }

    private function hasHighScoringExact(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->where('points', 2)
            ->whereHas('match', function ($q) {
                $q->where('status', 'finished')
                    ->whereRaw('(home_score + away_score) >= 5');
            })
            ->exists();
    }

    private function hasKnockoutPrediction(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q->where('stage', '!=', 'group'))
            ->exists();
    }

    private function hasOpeningMatchPrediction(User $user): bool
    {
        $openingIds = FootballMatch::query()->where('is_opening', true)->pluck('id');

        if ($openingIds->isEmpty()) {
            $first = FootballMatch::query()->orderBy('kickoff_at')->first();
            $openingIds = $first ? collect([$first->id]) : collect();
        }

        if ($openingIds->isEmpty()) {
            return false;
        }

        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereIn('match_id', $openingIds)
            ->exists();
    }

    private function hasDecisiveMatchPrediction(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q
                ->where('knockout_round', 'semi')
                ->orWhere('stage', 'semi'))
            ->exists();
    }

    private function hasFinalMatchPrediction(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->whereHas('match', fn ($q) => $q->where('knockout_round', 'final'))
            ->exists();
    }

    private function hasUnderdogWin(User $user): bool
    {
        return Prediction::query()
            ->where('user_id', $user->id)
            ->where('points', '>=', 1)
            ->whereHas('match', function ($q) {
                $q->where('status', 'finished')
                    ->where('home_is_favorite', true)
                    ->whereColumn('away_score', '>', 'home_score');
            })
            ->exists();
    }

    private function firstPredictionAt(User $user): ?Carbon
    {
        $first = Prediction::query()
            ->where('user_id', $user->id)
            ->orderBy('created_at')
            ->value('created_at');

        return $first ? Carbon::parse($first)->utc() : null;
    }

    private function qualifiesFaseGruposFirme(User $user): bool
    {
        $progress = $this->faseGruposFirmeProgress($user);

        return $progress !== null
            && $progress['target'] >= 8
            && $progress['current'] >= $progress['target'];
    }

    /**
     * @return array{current: int, target: int}|null
     */
    private function faseGruposFirmeProgress(User $user): ?array
    {
        $firstAt = $this->firstPredictionAt($user);
        if ($firstAt === null) {
            return null;
        }

        $openMatches = FootballMatch::query()
            ->where('stage', 'group')
            ->where('kickoff_at', '>', $firstAt)
            ->pluck('id');

        if ($openMatches->isEmpty()) {
            return ['current' => 0, 'target' => 0];
        }

        $predicted = Prediction::query()
            ->where('user_id', $user->id)
            ->whereIn('match_id', $openMatches)
            ->distinct('match_id')
            ->count('match_id');

        return [
            'current' => $predicted,
            'target' => $openMatches->count(),
        ];
    }

    public function bestPredictionDayStreak(User $user): int
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
            if ($days[$i - 1]->copy()->addDay()->isSameDay($days[$i])) {
                $current++;
                $best = max($best, $current);
            } else {
                $current = 1;
            }
        }

        return $best;
    }

    private function hasCompleteWeekend(User $user): bool
    {
        $weekends = FootballMatch::query()
            ->get(['id', 'kickoff_at'])
            ->groupBy(function (FootballMatch $match) {
                $kickoff = $match->kickoff_at?->utc();
                if ($kickoff === null) {
                    return null;
                }

                if (! in_array((int) $kickoff->dayOfWeek, [Carbon::SATURDAY, Carbon::SUNDAY], true)) {
                    return null;
                }

                return $kickoff->copy()->startOfWeek(Carbon::MONDAY)->toDateString();
            })
            ->filter(fn ($group, $key) => $key !== null && $key !== '');

        foreach ($weekends as $weekKey => $matches) {
            $weekendMatchIds = $matches
                ->filter(fn (FootballMatch $m) => in_array((int) $m->kickoff_at?->utc()->dayOfWeek, [Carbon::SATURDAY, Carbon::SUNDAY], true))
                ->pluck('id');

            if ($weekendMatchIds->count() < 4) {
                continue;
            }

            $predictedCount = Prediction::query()
                ->where('user_id', $user->id)
                ->whereIn('match_id', $weekendMatchIds)
                ->distinct('match_id')
                ->count('match_id');

            if ($predictedCount === $weekendMatchIds->count()) {
                return true;
            }
        }

        return false;
    }

    private function qualifiesNoTopo(): bool
    {
        return ($this->rankingContext['position'] ?? 0) === 1
            && ($this->rankingContext['scored_users'] ?? 0) >= 2;
    }

    private function qualifiesPodio(): bool
    {
        return ($this->rankingContext['position'] ?? PHP_INT_MAX) <= 3
            && ($this->rankingContext['scored_users'] ?? 0) >= 3;
    }

    private function qualifiesTop10(): bool
    {
        return ($this->rankingContext['position'] ?? PHP_INT_MAX) <= 10
            && ($this->rankingContext['scored_users'] ?? 0) >= 10;
    }

    private function qualifiesViceCampeao(): bool
    {
        if (! app(BolaoSettings::class)->tournamentClosed()) {
            return false;
        }

        return ($this->rankingContext['position'] ?? 0) === 2
            && ($this->rankingContext['scored_predictions'] ?? 0) >= 20;
    }

    private function qualifiesCampeaoDoBolao(): bool
    {
        if (! app(BolaoSettings::class)->tournamentClosed()) {
            return false;
        }

        return ($this->rankingContext['position'] ?? 0) === 1
            && ($this->rankingContext['scored_predictions'] ?? 0) >= 20;
    }
}
