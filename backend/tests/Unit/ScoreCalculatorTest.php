<?php

namespace Tests\Unit;

use App\Services\ScoreCalculator;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class ScoreCalculatorTest extends TestCase
{
    #[DataProvider('scoreCases')]
    public function test_calculates_points(int $ph, int $pa, int $ah, int $aa, int $expected): void
    {
        $calculator = new ScoreCalculator();

        $this->assertSame($expected, $calculator->calculate($ph, $pa, $ah, $aa));
    }

    public static function scoreCases(): array
    {
        return [
            'exact score' => [2, 1, 2, 1, 2],
            'correct winner' => [2, 0, 3, 1, 1],
            'correct draw' => [1, 1, 0, 0, 1],
            'wrong' => [2, 0, 0, 2, 0],
        ];
    }
}
