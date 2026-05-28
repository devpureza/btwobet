<?php

namespace App\Support;

use App\Models\Team;

/**
 * Detects openfootball bracket slot placeholders (e.g. 2A, 1E, 3A/B/C/D/F).
 */
final class TeamSlot
{
    public const GROUP_LETTERS = 'ABCDEFGHIJKL';

    public static function isPlaceholder(?Team $team): bool
    {
        if ($team === null) {
            return true;
        }

        $name = trim($team->name);
        $code = trim($team->code);

        if ($name === '' || $code === '') {
            return true;
        }

        $candidates = [$name, $code];
        foreach ($candidates as $value) {
            if (self::looksLikeSlot($value)) {
                return true;
            }
        }

        $lower = strtolower($name);
        foreach (['tbd', 'a definir', 'winner', 'vencedor', 'placeholder'] as $needle) {
            if (str_contains($lower, $needle)) {
                return true;
            }
        }

        return false;
    }

    public static function looksLikeSlot(string $value): bool
    {
        $value = trim($value);

        // 1A, 2B, 3A/B/C/D/F
        if (preg_match('/^\d+[A-L](?:\/\d+[A-L])*$/i', $value)) {
            return true;
        }

        return false;
    }
}
