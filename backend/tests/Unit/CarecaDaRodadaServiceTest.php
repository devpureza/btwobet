<?php

namespace Tests\Unit;

use App\Models\User;
use App\Services\CarecaDaRodadaService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class CarecaDaRodadaServiceTest extends TestCase
{
    use RefreshDatabase;

    private CarecaDaRodadaService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(CarecaDaRodadaService::class);
    }

    #[DataProvider('isoWeekRotationProvider')]
    public function test_rotation_index_follows_iso_week_mod_three(int $isoWeek, int $expectedIndex): void
    {
        $this->assertSame($expectedIndex, $this->service->rotationIndexForIsoWeek($isoWeek));
    }

    /**
     * @return array<string, array{int, int}>
     */
    public static function isoWeekRotationProvider(): array
    {
        return [
            'week 3 -> limirio' => [3, 0],
            'week 1 -> guilherme' => [1, 1],
            'week 2 -> igor' => [2, 2],
            'week 24 -> limirio' => [24, 0],
            'week 25 -> guilherme' => [25, 1],
            'week 26 -> igor' => [26, 2],
            'week 52 -> guilherme' => [52, 1],
        ];
    }

    public function test_get_careca_uses_db_user_when_found(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 11, 12, 0, 0, 'UTC'));

        User::factory()->create([
            'email' => 'limirio.oliveira@b2agencia.com.br',
            'name' => 'Limirio',
            'avatar_url' => '/storage/avatars/limirio.png',
        ]);

        $careca = $this->service->getCarecaOfWeek();

        $this->assertNotNull($careca);
        $this->assertSame('limirio.oliveira@b2agencia.com.br', $careca['email']);
        $this->assertSame('Limirio', $careca['display_name']);
        $this->assertSame('/storage/avatars/limirio.png', $careca['avatar_url']);
        $this->assertSame(24, $careca['iso_week']);
        $this->assertSame(0, $careca['rotation_index']);

        Carbon::setTestNow();
    }

    public function test_get_careca_falls_back_to_email_local_part_when_user_missing(): void
    {
        Carbon::setTestNow(Carbon::create(2026, 6, 15, 12, 0, 0, 'UTC'));

        $careca = $this->service->getCarecaOfWeek();

        $this->assertNotNull($careca);
        $this->assertSame('guilherme.fernandes@b2agencia.com.br', $careca['email']);
        $this->assertSame('Guilherme Fernandes', $careca['display_name']);
        $this->assertNull($careca['avatar_url']);
        $this->assertSame(25, $careca['iso_week']);
        $this->assertSame(1, $careca['rotation_index']);

        Carbon::setTestNow();
    }

    public function test_display_name_from_email_formats_local_part(): void
    {
        $this->assertSame(
            'Igor Fraga',
            $this->service->displayNameFromEmail('igor.fraga@b2agencia.com.br'),
        );
    }
}
