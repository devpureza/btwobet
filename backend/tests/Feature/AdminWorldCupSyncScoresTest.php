<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\BolaoSettings;
use App\Services\WorldCupScoreSyncService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Mockery;
use Tests\TestCase;

class AdminWorldCupSyncScoresTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }

    public function test_non_admin_cannot_trigger_worldcup_sync(): void
    {
        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/admin/worldcup/sync-scores')->assertForbidden();
    }

    public function test_admin_can_trigger_worldcup_sync_and_receives_stats(): void
    {
        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);

        $this->mock(WorldCupScoreSyncService::class, function ($mock) {
            $mock->shouldReceive('syncFromGloboEsporte')
                ->once()
                ->andReturn([
                    'found' => 12,
                    'matched' => 10,
                    'updated' => 3,
                    'finished' => 2,
                    'unmatched' => ['Time A x Time B'],
                ]);
        });

        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/worldcup/sync-scores')
            ->assertOk()
            ->assertJsonPath('message', 'Sincronização concluída.')
            ->assertJsonPath('data.found', 12)
            ->assertJsonPath('data.matched', 10)
            ->assertJsonPath('data.updated', 3)
            ->assertJsonPath('data.finished', 2)
            ->assertJsonPath('data.unmatched_count', 1);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }
}
