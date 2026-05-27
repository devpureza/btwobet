<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class WorldCup2026Seeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'devpureza@gmail.com'],
            [
                'name' => 'Mateus',
                'password' => Hash::make('12345678'),
                'is_admin' => true,
                'approval_status' => User::STATUS_APPROVED,
            ],
        );
    }
}
