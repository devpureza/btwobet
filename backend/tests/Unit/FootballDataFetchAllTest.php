<?php // backend/tests/Unit/FootballDataFetchAllTest.php
namespace Tests\Unit;
use App\Services\ScoreSync\FootballDataScoreProvider;
use PHPUnit\Framework\TestCase;

class FootballDataFetchAllTest extends TestCase
{
    public function test_parses_resolved_and_unresolved_games(): void
    {
        $payload = ['matches' => [
            ['id' => 1, 'stage' => 'GROUP_STAGE', 'utcDate' => '2026-06-11T19:00:00Z',
             'homeTeam' => ['shortName' => 'Mexico'], 'awayTeam' => ['shortName' => 'South Africa']],
            ['id' => 99, 'stage' => 'LAST_16', 'utcDate' => '2026-07-04T17:00:00Z',
             'homeTeam' => ['id' => null, 'name' => null], 'awayTeam' => ['id' => null, 'name' => null]],
        ]];
        $rows = (new FootballDataScoreProvider())->parseAll($payload);
        $this->assertCount(2, $rows);
        $this->assertSame('group', $rows[0]['stage']);
        $this->assertSame('Mexico', $rows[0]['home_name']);
        $this->assertSame('knockout', $rows[1]['stage']);
        $this->assertNull($rows[1]['home_name']);
        $this->assertSame(99, $rows[1]['external_id']);
    }
}
