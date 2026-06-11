<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Models\Team;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class HallOfWeekService
{
    private const CACHE_TTL_SECONDS = 300;

    /**
     * Semana corrente em UTC (segunda 00:00 — domingo 23:59:59), ISO-8601.
     */
    public function weekBoundsUtc(): array
    {
        $start = Carbon::now('UTC')->startOfWeek(Carbon::MONDAY);
        $end = Carbon::now('UTC')->endOfWeek(Carbon::SUNDAY);

        return [$start, $end];
    }

    public function getHallOfWeek(): array
    {
        [$start, $end] = $this->weekBoundsUtc();
        $cacheKey = 'hall_of_week:'.$start->toDateString();

        return Cache::remember($cacheKey, self::CACHE_TTL_SECONDS, function () use ($start, $end) {
            return [
                'period_label' => 'Esta semana',
                'week_start' => $start->toIso8601String(),
                'week_end' => $end->toIso8601String(),
                'fame' => $this->buildFame($start, $end),
                'shame' => $this->buildShame($start, $end),
            ];
        });
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function buildFame(Carbon $start, Carbon $end): array
    {
        $entries = [];

        $gold = $this->rodadaOuro($start, $end);
        if ($gold !== null) {
            $entries[] = $gold;
        }

        $exact = $this->placarExatoSemana($start, $end);
        if ($exact !== null) {
            $entries[] = $exact;
        }

        return $entries;
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function buildShame(Carbon $start, Carbon $end): array
    {
        $inverted = $this->profeciaInvertida($start, $end);

        return $inverted !== null ? [$inverted] : [];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function rodadaOuro(Carbon $start, Carbon $end): ?array
    {
        $row = DB::table('predictions')
            ->join('matches', 'predictions.match_id', '=', 'matches.id')
            ->join('users', 'predictions.user_id', '=', 'users.id')
            ->where('users.approval_status', User::STATUS_APPROVED)
            ->whereIn('matches.status', ['live', 'finished'])
            ->whereBetween('matches.kickoff_at', [$start, $end])
            ->groupBy('users.id', 'users.name', 'users.avatar_url')
            ->select([
                'users.id as user_id',
                'users.name',
                'users.avatar_url',
                DB::raw('COALESCE(SUM(predictions.points), 0) as week_points'),
            ])
            ->orderByDesc('week_points')
            ->orderBy('users.name')
            ->first();

        if ($row === null || (int) $row->week_points <= 0) {
            return null;
        }

        return $this->entry(
            key: 'rodada_ouro',
            title: 'Rodada de ouro',
            subtitle: sprintf('%d pts na semana', (int) $row->week_points),
            userId: (int) $row->user_id,
            name: $row->name,
            avatarUrl: $row->avatar_url,
        );
    }

    /**
     * @return array<string, mixed>|null
     */
    private function placarExatoSemana(Carbon $start, Carbon $end): ?array
    {
        $prediction = Prediction::query()
            ->with(['user', 'match.homeTeam', 'match.awayTeam'])
            ->where('points', 2)
            ->whereHas('user', fn ($q) => $q->where('approval_status', User::STATUS_APPROVED))
            ->whereHas('match', function ($q) use ($start, $end) {
                $q->where('status', 'finished')
                    ->whereBetween('kickoff_at', [$start, $end]);
            })
            ->join('matches', 'predictions.match_id', '=', 'matches.id')
            ->join('users', 'predictions.user_id', '=', 'users.id')
            ->orderByDesc('matches.kickoff_at')
            ->orderBy('users.name')
            ->select('predictions.*')
            ->first();

        if ($prediction === null || $prediction->match === null || $prediction->user === null) {
            return null;
        }

        $match = $prediction->match;
        $scoreLine = $this->formatMatchScoreLine($match);

        return $this->entry(
            key: 'placar_exato_semana',
            title: 'Placar exato da semana',
            subtitle: $scoreLine,
            userId: $prediction->user_id,
            name: $prediction->user->name,
            avatarUrl: $prediction->user->avatar_url,
            matchId: $match->id,
        );
    }

    /**
     * @return array<string, mixed>|null
     */
    private function profeciaInvertida(Carbon $start, Carbon $end): ?array
    {
        $predictions = Prediction::query()
            ->with(['user', 'match.homeTeam', 'match.awayTeam'])
            ->where('points', 0)
            ->whereHas('user', fn ($q) => $q->where('approval_status', User::STATUS_APPROVED))
            ->whereHas('match', function ($q) use ($start, $end) {
                $q->where('status', 'finished')
                    ->whereBetween('kickoff_at', [$start, $end])
                    ->whereNotNull('home_score')
                    ->whereNotNull('away_score');
            })
            ->get();

        $worst = $predictions
            ->filter(fn (Prediction $p) => $this->isInvertedBigMiss($p))
            ->sortByDesc(fn (Prediction $p) => abs($p->home_score - $p->away_score))
            ->first();

        if ($worst === null || $worst->match === null || $worst->user === null) {
            return null;
        }

        $predicted = sprintf('%d×%d', $worst->home_score, $worst->away_score);
        $actual = sprintf('%d×%d', $worst->match->home_score, $worst->match->away_score);

        return $this->entry(
            key: 'profecia_invertida',
            title: 'Profecia invertida',
            subtitle: sprintf('Previu %s, saiu %s', $predicted, $actual),
            userId: $worst->user_id,
            name: $worst->user->name,
            avatarUrl: $worst->user->avatar_url,
            matchId: $worst->match_id,
        );
    }

    private function isInvertedBigMiss(Prediction $prediction): bool
    {
        $match = $prediction->match;
        if ($match === null || $match->home_score === null || $match->away_score === null) {
            return false;
        }

        $predictedDiff = $prediction->home_score <=> $prediction->away_score;
        $actualDiff = $match->home_score <=> $match->away_score;

        if ($predictedDiff === 0 || $actualDiff === 0) {
            return false;
        }

        if ($predictedDiff === $actualDiff) {
            return false;
        }

        $margin = abs($prediction->home_score - $prediction->away_score);

        return $margin >= 2;
    }

    private function formatMatchScoreLine(FootballMatch $match): string
    {
        $home = $this->teamLabel($match->homeTeam);
        $away = $this->teamLabel($match->awayTeam);

        return sprintf(
            '%s %d×%d %s',
            $home,
            $match->home_score,
            $match->away_score,
            $away,
        );
    }

    private function teamLabel(?Team $team): string
    {
        if ($team === null) {
            return '—';
        }

        return $team->name;
    }

    /**
     * @return array<string, mixed>
     */
    private function entry(
        string $key,
        string $title,
        string $subtitle,
        int $userId,
        string $name,
        ?string $avatarUrl,
        ?int $matchId = null,
    ): array {
        $payload = [
            'key' => $key,
            'title' => $title,
            'subtitle' => $subtitle,
            'user_id' => $userId,
            'display_name' => $name,
            'avatar_url' => $avatarUrl,
        ];

        if ($matchId !== null) {
            $payload['match_id'] = $matchId;
        }

        return $payload;
    }
}
