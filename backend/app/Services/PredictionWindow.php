<?php

namespace App\Services;

use App\Models\FootballMatch;
use App\Models\Prediction;
use App\Support\TeamSlot;
use Carbon\Carbon;

class PredictionWindow
{
    public const COMMUNITY_REVEAL_HOURS_BEFORE_KICKOFF = 2;

    public function __construct(private readonly BolaoSettings $settings) {}

    public function communityPredictionsVisible(FootballMatch $match): bool
    {
        if (in_array($match->status, ['live', 'finished'], true)) {
            return true;
        }

        return now()->gte(
            $match->kickoff_at->copy()->subHours(self::COMMUNITY_REVEAL_HOURS_BEFORE_KICKOFF)
        );
    }

    /**
     * @return array{can_submit: bool, reason: string|null, deadline_at: string|null}
     */
    public function evaluate(FootballMatch $match, ?Prediction $existing): array
    {
        if ($existing !== null) {
            return [
                'can_submit' => false,
                'reason' => 'Palpite já registrado. Não é possível alterar.',
                'deadline_at' => null,
            ];
        }

        if ($this->settings->lockAll()) {
            return [
                'can_submit' => false,
                'reason' => 'Palpites temporariamente bloqueados pelo administrador.',
                'deadline_at' => null,
            ];
        }

        if ($match->status !== 'scheduled') {
            return [
                'can_submit' => false,
                'reason' => 'Jogo já iniciado ou finalizado.',
                'deadline_at' => null,
            ];
        }

        if (! $this->teamsAreDefined($match)) {
            return [
                'can_submit' => false,
                'reason' => 'Aguardando definição dos times.',
                'deadline_at' => null,
            ];
        }

        $deadline = $this->deadlineForMatch($match);
        if ($deadline === null) {
            return [
                'can_submit' => false,
                'reason' => 'Fase do jogo não permite palpites.',
                'deadline_at' => null,
            ];
        }

        if (now()->gte($deadline)) {
            $reason = $match->stage === 'group'
                ? 'Prazo da fase de grupos encerrado.'
                : 'Palpites fecham '.$this->settings->knockoutHoursBefore().'h antes do jogo.';

            return [
                'can_submit' => false,
                'reason' => $reason,
                'deadline_at' => $deadline->toIso8601String(),
            ];
        }

        if (now()->gte($match->kickoff_at)) {
            return [
                'can_submit' => false,
                'reason' => 'Horário do jogo já passou.',
                'deadline_at' => $deadline->toIso8601String(),
            ];
        }

        return [
            'can_submit' => true,
            'reason' => null,
            'deadline_at' => $deadline->toIso8601String(),
        ];
    }

    public function deadlineForMatch(FootballMatch $match): ?Carbon
    {
        if ($match->stage === 'group') {
            return $this->settings->groupDeadline();
        }

        if ($match->stage === 'knockout') {
            return $match->kickoff_at->copy()->subHours($this->settings->knockoutHoursBefore());
        }

        return null;
    }

    public function isOpenForNewPredictions(FootballMatch $match): bool
    {
        return $this->evaluate($match, null)['can_submit'];
    }

    public function teamsAreDefined(FootballMatch $match): bool
    {
        $match->loadMissing(['homeTeam', 'awayTeam']);

        return ! TeamSlot::isPlaceholder($match->homeTeam)
            && ! TeamSlot::isPlaceholder($match->awayTeam);
    }
}
