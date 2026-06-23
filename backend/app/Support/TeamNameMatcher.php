<?php

namespace App\Support;

use App\Models\Team;
use Illuminate\Support\Str;

class TeamNameMatcher
{
    /** Nomes usados no ge.globo => nome salvo no banco (inglês ou PT do import). */
    private const GE_ALIASES = [
        'RD Congo' => 'DR Congo',
        'República Democrática do Congo' => 'DR Congo',
        'Congo DR' => 'DR Congo',
        'Coreia do Sul' => 'South Korea',
        'Korea Republic' => 'South Korea',
        'Estados Unidos' => 'USA',
        'Estados Unidos da América' => 'USA',
        'Holanda' => 'Netherlands',
        'Bósnia' => 'Bosnia & Herzegovina',
        'Bósnia e Herzegovina' => 'Bosnia & Herzegovina',
        'Bosnia-H.' => 'Bosnia & Herzegovina',
        'República Tcheca' => 'Czech Republic',
        'Czechia' => 'Czech Republic',
        'Costa do Marfim' => 'Ivory Coast',
        'Irã' => 'Iran',
        'Arábia Saudita' => 'Saudi Arabia',
        'Nova Zelândia' => 'New Zealand',
        'País de Gales' => 'Wales',
        'Suíça' => 'Switzerland',
        'Turquia' => 'Turkey',
        'Panamá' => 'Panama',
    ];

    /** @var array<string, Team>|null */
    private static ?array $byNormalized = null;

    public static function normalize(string $name): string
    {
        return Str::lower(Str::ascii(trim($name)));
    }

    public static function resolveGeName(string $geName): string
    {
        return self::GE_ALIASES[$geName] ?? $geName;
    }

    public static function findTeam(string $geName): ?Team
    {
        self::warmIndex();

        $candidates = array_unique([
            $geName,
            self::resolveGeName($geName),
            WorldCupTeamNames::toPortuguese(self::resolveGeName($geName)),
            WorldCupTeamNames::toPortuguese($geName),
        ]);

        foreach ($candidates as $candidate) {
            $key = self::normalize($candidate);
            if (isset(self::$byNormalized[$key])) {
                return self::$byNormalized[$key];
            }
        }

        return null;
    }

    private static function warmIndex(): void
    {
        if (self::$byNormalized !== null) {
            return;
        }

        self::$byNormalized = [];
        foreach (Team::query()->get(['id', 'name', 'code']) as $team) {
            $keys = [
                self::normalize($team->name),
                self::normalize(WorldCupTeamNames::toPortuguese($team->name)),
            ];
            foreach ($keys as $key) {
                self::$byNormalized[$key] = $team;
            }
        }

        foreach (self::GE_ALIASES as $ge => $canonical) {
            $team = self::$byNormalized[self::normalize($canonical)]
                ?? self::$byNormalized[self::normalize(WorldCupTeamNames::toPortuguese($canonical))]
                ?? null;
            if ($team) {
                self::$byNormalized[self::normalize($ge)] = $team;
            }
        }
    }

    public static function resetIndex(): void
    {
        self::$byNormalized = null;
    }
}
