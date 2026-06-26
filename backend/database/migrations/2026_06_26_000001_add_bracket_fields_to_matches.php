<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->unsignedBigInteger('external_id')->nullable()->unique()->after('id');
            $table->boolean('teams_locked')->default(false)->after('status');
            $table->timestamp('teams_defined_at')->nullable()->after('teams_locked');
        });
    }

    public function down(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn(['external_id', 'teams_locked', 'teams_defined_at']);
        });
    }
};
