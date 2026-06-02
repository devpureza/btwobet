<?php

namespace App\Enums;

enum AchievementSlug: string
{
    case FirstPrediction = 'first_prediction';
    case ExactScore = 'exact_score';
    case PointsHatTrick = 'points_hat_trick';
    case RoundGold = 'round_gold';
    case ThreeDayStreak = 'three_day_streak';
    case CenturyPoints = 'century_points';
    case LastCall = 'last_call';
    case FinalProphet = 'final_prophet';
}
