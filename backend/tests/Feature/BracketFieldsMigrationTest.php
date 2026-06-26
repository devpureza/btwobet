<?php // backend/tests/Feature/BracketFieldsMigrationTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class BracketFieldsMigrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_matches_has_bracket_columns(): void
    {
        $this->assertTrue(Schema::hasColumns('matches', ['external_id', 'teams_locked', 'teams_defined_at']));
    }

    public function test_model_casts_and_fillable(): void
    {
        $m = new FootballMatch();
        $m->fill(['external_id' => 537417, 'teams_locked' => true]);
        $this->assertSame(537417, $m->external_id);
        $this->assertTrue($m->teams_locked);
    }
}
