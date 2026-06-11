<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FootballMatch;
use App\Services\PredictionWindow;
use App\Support\TeamSlot;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MatchController extends Controller
{
    public function __construct(private readonly PredictionWindow $window) {}

    private const TEAM_PT = [
        'Mexico' => 'México',
        'South Africa' => 'África do Sul',
        'South Korea' => 'Coreia do Sul',
        'Czech Republic' => 'República Tcheca',
        'Bosnia & Herzegovina' => 'Bósnia e Herzegovina',
        'Switzerland' => 'Suíça',
        'Brazil' => 'Brasil',
        'Morocco' => 'Marrocos',
        'Haiti' => 'Haiti',
        'Scotland' => 'Escócia',
        'USA' => 'Estados Unidos',
        'United States' => 'Estados Unidos',
        'Paraguay' => 'Paraguai',
        'Australia' => 'Austrália',
        'Turkey' => 'Turquia',
        'Germany' => 'Alemanha',
        'Curaçao' => 'Curaçao',
        'Ivory Coast' => 'Costa do Marfim',
        'Ecuador' => 'Equador',
        'Netherlands' => 'Holanda',
        'Japan' => 'Japão',
        'Sweden' => 'Suécia',
        'Tunisia' => 'Tunísia',
        'Belgium' => 'Bélgica',
        'Egypt' => 'Egito',
        'Iran' => 'Irã',
        'New Zealand' => 'Nova Zelândia',
        'Spain' => 'Espanha',
        'Cape Verde' => 'Cabo Verde',
        'Saudi Arabia' => 'Arábia Saudita',
        'Uruguay' => 'Uruguai',
        'France' => 'França',
        'Senegal' => 'Senegal',
        'Iraq' => 'Iraque',
        'Norway' => 'Noruega',
        'Argentina' => 'Argentina',
        'Algeria' => 'Argélia',
        'Austria' => 'Áustria',
        'Jordan' => 'Jordânia',
        'Portugal' => 'Portugal',
        'DR Congo' => 'RD Congo',
        'Uzbekistan' => 'Uzbequistão',
        'Colombia' => 'Colômbia',
        'England' => 'Inglaterra',
        'Croatia' => 'Croácia',
        'Ghana' => 'Gana',
        'Panama' => 'Panamá',
        'Canada' => 'Canadá',
        'Qatar' => 'Catar',
    ];

    private const VENUE_PT = [
        'Mexico City' => 'Cidade do México',
        'Guadalajara (Zapopan)' => 'Guadalajara (Zapopan)',
        'Monterrey (Guadalupe)' => 'Monterrey (Guadalupe)',
        'Toronto' => 'Toronto',
        'Vancouver' => 'Vancouver',
        'Los Angeles (Inglewood)' => 'Los Angeles (Inglewood)',
        'San Francisco Bay Area (Santa Clara)' => 'Baía de San Francisco (Santa Clara)',
        'Seattle' => 'Seattle',
        'Houston' => 'Houston',
        'Dallas (Arlington)' => 'Dallas (Arlington)',
        'Kansas City' => 'Kansas City',
        'Atlanta' => 'Atlanta',
        'Miami (Miami Gardens)' => 'Miami (Miami Gardens)',
        'Boston (Foxborough)' => 'Boston (Foxborough)',
        'Philadelphia' => 'Filadélfia',
        'New York/New Jersey (East Rutherford)' => 'Nova York/Nova Jersey (East Rutherford)',
    ];

    public function index(Request $request): JsonResponse
    {
        $matches = FootballMatch::with(['homeTeam', 'awayTeam'])
            ->orderBy('kickoff_at')
            ->get()
            ->map(fn (FootballMatch $match) => $this->transform($match, $request->user()?->id));

        return response()->json(['data' => $matches]);
    }

    private function transform(FootballMatch $match, ?int $userId): array
    {
        $prediction = null;
        if ($userId) {
            $prediction = $match->predictions()->where('user_id', $userId)->first();
        }

        $access = $this->window->evaluate($match, $prediction);

        return [
            'id' => $match->id,
            'kickoff_at' => $match->kickoff_at->toIso8601String(),
            'stage' => $match->stage,
            'group_name' => $match->group_name,
            'venue' => $this->translateVenue($match->venue),
            'status' => $match->status,
            'home_team' => $this->teamPayload($match->homeTeam),
            'away_team' => $this->teamPayload($match->awayTeam),
            'result' => $match->status === 'finished' ? [
                'home_score' => $match->home_score,
                'away_score' => $match->away_score,
            ] : null,
            'live_score' => $this->liveScorePayload($match),
            'teams_defined' => $this->window->teamsAreDefined($match),
            'open_for_predictions' => $access['can_submit'],
            'prediction_deadline_at' => $access['deadline_at'],
            'prediction_lock_reason' => $access['reason'],
            'my_prediction' => $prediction ? [
                'home_score' => $prediction->home_score,
                'away_score' => $prediction->away_score,
                'points' => $prediction->points,
            ] : null,
        ];
    }

    /**
     * @return array{home_score: int, away_score: int}|null
     */
    private function liveScorePayload(FootballMatch $match): ?array
    {
        if ($match->status === 'finished'
            || $match->home_score === null
            || $match->away_score === null) {
            return null;
        }

        if ($match->status === 'live') {
            return [
                'home_score' => $match->home_score,
                'away_score' => $match->away_score,
            ];
        }

        if ($match->status === 'scheduled' && $match->kickoff_at->isPast()) {
            return [
                'home_score' => $match->home_score,
                'away_score' => $match->away_score,
            ];
        }

        return null;
    }

    private function teamPayload($team): array
    {
        return [
            'id' => $team->id,
            'code' => $team->code,
            'name' => $this->translateTeamName($team->name),
            'flag_url' => $team->flag_url,
            'is_placeholder' => TeamSlot::isPlaceholder($team),
        ];
    }

    private function translateTeamName(string $name): string
    {
        return self::TEAM_PT[$name] ?? $name;
    }

    private function translateVenue(?string $venue): ?string
    {
        if ($venue === null || $venue === '') {
            return $venue;
        }

        return self::VENUE_PT[$venue] ?? $venue;
    }
}
