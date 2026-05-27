<?php

namespace App\Services;

class ScoreCalculator
{
    public function calculate(int $predictedHome, int $predictedAway, int $actualHome, int $actualAway): int
    {
        if ($predictedHome === $actualHome && $predictedAway === $actualAway) {
            return 2;
        }

        $predictedDiff = $predictedHome <=> $predictedAway;
        $actualDiff = $actualHome <=> $actualAway;

        return $predictedDiff === $actualDiff ? 1 : 0;
    }
}
