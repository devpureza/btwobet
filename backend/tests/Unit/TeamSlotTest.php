<?php

namespace Tests\Unit;

use App\Models\Team;
use App\Support\TeamSlot;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class TeamSlotTest extends TestCase
{
    #[DataProvider('placeholderNamesProvider')]
    public function test_detects_openfootball_slot_placeholders(string $name): void
    {
        $team = new Team(['code' => $name, 'name' => $name]);

        $this->assertTrue(TeamSlot::isPlaceholder($team));
    }

    public static function placeholderNamesProvider(): array
    {
        return [
            ['2A'],
            ['1E'],
            ['3A/B/C/D/F'],
        ];
    }

    public function test_real_team_is_not_placeholder(): void
    {
        $team = new Team(['code' => 'BRA', 'name' => 'Brazil']);

        $this->assertFalse(TeamSlot::isPlaceholder($team));
    }
}
