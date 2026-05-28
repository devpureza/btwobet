<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminUserAvatarTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_upload_avatar_for_another_user(): void
    {
        Storage::fake('public');

        $admin = User::factory()->create([
            'is_admin' => true,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $player = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        Sanctum::actingAs($admin);

        $response = $this->post('/api/admin/users/'.$player->id.'/avatar', [
            'file' => UploadedFile::fake()->image('avatar.jpg'),
        ], ['Accept' => 'application/json']);

        $response->assertOk()
            ->assertJsonPath('data.id', $player->id);

        $avatarUrl = $response->json('data.avatar_url');
        $this->assertIsString($avatarUrl);
        $this->assertStringStartsWith('/storage/avatars/user-'.$player->id.'.', $avatarUrl);
        $this->assertStringContainsString('?v=', $avatarUrl);

        $player->refresh();
        $this->assertSame($avatarUrl, $player->avatar_url);
        Storage::disk('public')->assertExists('avatars/user-'.$player->id.'.jpg');
    }

    public function test_non_admin_cannot_upload_user_avatar(): void
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'is_admin' => false,
            'approval_status' => User::STATUS_APPROVED,
        ]);
        $target = User::factory()->create(['approval_status' => User::STATUS_APPROVED]);

        Sanctum::actingAs($user);

        $this->post('/api/admin/users/'.$target->id.'/avatar', [
            'file' => UploadedFile::fake()->image('avatar.jpg'),
        ], ['Accept' => 'application/json'])->assertForbidden();
    }
}
