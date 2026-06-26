<?php

namespace Tests\Unit;

use App\Models\Team;
use App\Support\TeamSlot;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class TeamSlotTest extends TestCase
{
    #[DataProvider('placeholderNamesProvider')]
    public function test_detects_placeholder_teams(string $name): void
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
            ['W73'],
            ['L101'],
        ];
    }

    public function test_real_team_is_not_placeholder(): void
    {
        $team = new Team(['code' => 'BRA', 'name' => 'Brazil']);
        $this->assertFalse(TeamSlot::isPlaceholder($team));
    }

    public function test_winner_loser_slots_via_looks_like_slot(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('W73'));
        $this->assertTrue(TeamSlot::looksLikeSlot('L101'));
        $this->assertTrue(TeamSlot::looksLikeSlot('w12'));
    }

    public function test_group_slots_and_real_names_via_looks_like_slot(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('2A'));
        $this->assertTrue(TeamSlot::looksLikeSlot('3A/B/C/D/F'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Brasil'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Wales'));
    }
}
