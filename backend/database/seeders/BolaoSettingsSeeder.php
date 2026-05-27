<?php

namespace Database\Seeders;

use App\Services\BolaoSettings;
use Illuminate\Database\Seeder;

class BolaoSettingsSeeder extends Seeder
{
    public function run(): void
    {
        app(BolaoSettings::class)->seedDefaultsIfMissing();
    }
}
