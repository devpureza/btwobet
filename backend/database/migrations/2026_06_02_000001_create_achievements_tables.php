<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('matches', function (Blueprint $table) {
            $table->string('knockout_round')->nullable()->after('stage');
        });

        Schema::create('achievements', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('name');
            $table->text('description');
            $table->string('tier');
            $table->string('rule_type');
            $table->json('rule_metadata')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_trackable')->default(false);
            $table->timestamps();
        });

        Schema::create('user_achievements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('achievement_id')->constrained()->cascadeOnDelete();
            $table->timestamp('unlocked_at');
            $table->timestamps();

            $table->unique(['user_id', 'achievement_id']);
        });

        $now = now();
        $rows = [
            [
                'slug' => 'first_prediction',
                'name' => 'Primeiro palpite',
                'description' => 'Enviou o primeiro palpite no bolão.',
                'tier' => 'bronze',
                'rule_type' => 'first_prediction',
                'rule_metadata' => null,
                'sort_order' => 1,
                'is_trackable' => false,
            ],
            [
                'slug' => 'exact_score',
                'name' => 'Placar exato',
                'description' => 'Acertou o placar completo de um jogo.',
                'tier' => 'silver',
                'rule_type' => 'exact_score',
                'rule_metadata' => null,
                'sort_order' => 2,
                'is_trackable' => false,
            ],
            [
                'slug' => 'points_hat_trick',
                'name' => 'Hat-trick de pontos',
                'description' => 'Pontuou em 3 jogos finalizados seguidos.',
                'tier' => 'gold',
                'rule_type' => 'points_hat_trick',
                'rule_metadata' => json_encode(['required_streak' => 3]),
                'sort_order' => 3,
                'is_trackable' => true,
            ],
            [
                'slug' => 'round_gold',
                'name' => 'Ouro da rodada',
                'description' => 'Liderou a pontuação em um dia de jogos (UTC).',
                'tier' => 'gold',
                'rule_type' => 'round_gold',
                'rule_metadata' => null,
                'sort_order' => 4,
                'is_trackable' => false,
            ],
            [
                'slug' => 'three_day_streak',
                'name' => 'Sequência de 3 dias',
                'description' => 'Palpitou em 3 dias seguidos.',
                'tier' => 'silver',
                'rule_type' => 'three_day_streak',
                'rule_metadata' => json_encode(['required_days' => 3]),
                'sort_order' => 5,
                'is_trackable' => true,
            ],
            [
                'slug' => 'century_points',
                'name' => 'Centenário',
                'description' => 'Acumulou 100 pontos no bolão.',
                'tier' => 'platinum',
                'rule_type' => 'century_points',
                'rule_metadata' => json_encode(['target_points' => 100]),
                'sort_order' => 6,
                'is_trackable' => true,
            ],
            [
                'slug' => 'last_call',
                'name' => 'Em cima da hora',
                'description' => 'Palpitou com menos de 1 hora para o apito inicial.',
                'tier' => 'bronze',
                'rule_type' => 'last_call',
                'rule_metadata' => json_encode(['max_hours_before' => 1]),
                'sort_order' => 7,
                'is_trackable' => false,
            ],
            [
                'slug' => 'final_prophet',
                'name' => 'Profeta da final',
                'description' => 'Acertou o placar exato na final da Copa.',
                'tier' => 'platinum',
                'rule_type' => 'final_prophet',
                'rule_metadata' => null,
                'sort_order' => 8,
                'is_trackable' => false,
            ],
        ];

        foreach ($rows as &$row) {
            $row['created_at'] = $now;
            $row['updated_at'] = $now;
        }
        unset($row);

        DB::table('achievements')->insert($rows);
    }

    public function down(): void
    {
        Schema::dropIfExists('user_achievements');
        Schema::dropIfExists('achievements');
        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn('knockout_round');
        });
    }
};
