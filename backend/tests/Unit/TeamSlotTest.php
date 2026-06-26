<?php // backend/tests/Unit/TeamSlotTest.php
namespace Tests\Unit;
use App\Support\TeamSlot;
use PHPUnit\Framework\TestCase;

class TeamSlotTest extends TestCase
{
    public function test_winner_loser_slots_are_placeholders(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('W73'));
        $this->assertTrue(TeamSlot::looksLikeSlot('L101'));
        $this->assertTrue(TeamSlot::looksLikeSlot('w12'));
    }

    public function test_group_slots_still_work_and_real_names_dont(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('2A'));
        $this->assertTrue(TeamSlot::looksLikeSlot('3A/B/C/D/F'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Brasil'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Wales')); // não confundir W+letras
    }
}
