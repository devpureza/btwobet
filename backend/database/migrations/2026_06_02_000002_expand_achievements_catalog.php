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
            $table->boolean('is_opening')->default(false)->after('knockout_round');
            $table->boolean('home_is_favorite')->nullable()->after('is_opening');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('last_ranking_position')->nullable()->after('avatar_url');
            $table->unsignedSmallInteger('ranking_first_streak')->default(0)->after('last_ranking_position');
        });

        $slugMap = [
            'first_prediction' => 'primeiro-palpite',
            'exact_score' => 'placar-na-mosca',
        ];

        foreach ($slugMap as $old => $new) {
            DB::table('achievements')->where('slug', $old)->update(['slug' => $new]);
        }

        $obsolete = [
            'points_hat_trick',
            'round_gold',
            'three_day_streak',
            'century_points',
            'last_call',
            'final_prophet',
        ];

        $obsoleteIds = DB::table('achievements')->whereIn('slug', $obsolete)->pluck('id');
        if ($obsoleteIds->isNotEmpty()) {
            DB::table('user_achievements')->whereIn('achievement_id', $obsoleteIds)->delete();
            DB::table('achievements')->whereIn('id', $obsoleteIds)->delete();
        }

        $now = now();
        $rows = $this->catalogRows();

        foreach ($rows as $row) {
            $existing = DB::table('achievements')->where('slug', $row['slug'])->first();

            if ($existing) {
                DB::table('achievements')->where('id', $existing->id)->update([
                    'name' => $row['name'],
                    'description' => $row['description'],
                    'tier' => $row['tier'],
                    'rule_type' => $row['rule_type'],
                    'rule_metadata' => $row['rule_metadata'],
                    'sort_order' => $row['sort_order'],
                    'is_trackable' => $row['is_trackable'],
                    'updated_at' => $now,
                ]);
            } else {
                DB::table('achievements')->insert(array_merge($row, [
                    'created_at' => $now,
                    'updated_at' => $now,
                ]));
            }
        }

        if (! DB::table('settings')->where('key', 'tournament.tournament_closed')->exists()) {
            DB::table('settings')->insert([
                'key' => 'tournament.tournament_closed',
                'value' => '0',
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['last_ranking_position', 'ranking_first_streak']);
        });

        Schema::table('matches', function (Blueprint $table) {
            $table->dropColumn(['is_opening', 'home_is_favorite']);
        });

        DB::table('settings')->where('key', 'tournament.tournament_closed')->delete();
    }

    /**
     * @return list<array<string, mixed>>
     */
    private function catalogRows(): array
    {
        return [
            [
                'slug' => 'primeiro-palpite',
                'name' => 'Primeiro Palpite',
                'description' => 'Você entrou em campo: registrou seu primeiro palpite.',
                'tier' => 'bronze',
                'rule_type' => 'primeiro_palpite',
                'rule_metadata' => null,
                'sort_order' => 1,
                'is_trackable' => false,
            ],
            [
                'slug' => 'em-campo',
                'name' => 'Em Campo',
                'description' => 'Cinco palpites registrados — você está jogando o bolão de verdade.',
                'tier' => 'bronze',
                'rule_type' => 'em_campo',
                'rule_metadata' => json_encode(['target' => 5]),
                'sort_order' => 2,
                'is_trackable' => true,
            ],
            [
                'slug' => 'placar-na-mosca',
                'name' => 'Placar na Mosca',
                'description' => 'Acertou o placar exato em um jogo (2 pontos).',
                'tier' => 'silver',
                'rule_type' => 'placar_na_mosca',
                'rule_metadata' => null,
                'sort_order' => 3,
                'is_trackable' => false,
            ],
            [
                'slug' => 'trio-perfeito',
                'name' => 'Trio Perfeito',
                'description' => 'Três placares exatos no bolão — precisão de craque.',
                'tier' => 'silver',
                'rule_type' => 'trio_perfeito',
                'rule_metadata' => json_encode(['target' => 3]),
                'sort_order' => 4,
                'is_trackable' => true,
            ],
            [
                'slug' => 'pontuador',
                'name' => 'Pontuador',
                'description' => 'Somou 10 pontos no ranking do bolão.',
                'tier' => 'bronze',
                'rule_type' => 'pontuador',
                'rule_metadata' => json_encode(['target' => 10]),
                'sort_order' => 5,
                'is_trackable' => true,
            ],
            [
                'slug' => 'no-topo',
                'name' => 'No Topo',
                'description' => 'Chegou ao 1º lugar do ranking geral (mesmo que por um instante).',
                'tier' => 'gold',
                'rule_type' => 'no_topo',
                'rule_metadata' => null,
                'sort_order' => 6,
                'is_trackable' => false,
            ],
            [
                'slug' => 'podio',
                'name' => 'Pódio',
                'description' => 'Entrou no top 3 do ranking geral.',
                'tier' => 'silver',
                'rule_type' => 'podio',
                'rule_metadata' => null,
                'sort_order' => 7,
                'is_trackable' => false,
            ],
            [
                'slug' => 'presenca-confirmada',
                'name' => 'Presença Confirmada',
                'description' => 'Palpitou em 3 dias diferentes com jogos — ritmo de torcedor.',
                'tier' => 'bronze',
                'rule_type' => 'presenca_confirmada',
                'rule_metadata' => json_encode(['target' => 3]),
                'sort_order' => 8,
                'is_trackable' => true,
            ],
            [
                'slug' => 'bem-vindo',
                'name' => 'Bem-vindo',
                'description' => 'Conta criada — a Copa te espera.',
                'tier' => 'bronze',
                'rule_type' => 'bem_vindo',
                'rule_metadata' => null,
                'sort_order' => 9,
                'is_trackable' => false,
            ],
            [
                'slug' => 'perfil-com-cara',
                'name' => 'Perfil com Cara',
                'description' => 'Adicionou foto no perfil.',
                'tier' => 'bronze',
                'rule_type' => 'perfil_com_cara',
                'rule_metadata' => null,
                'sort_order' => 10,
                'is_trackable' => false,
            ],
            [
                'slug' => 'dez-palpites',
                'name' => 'Dez Palpites',
                'description' => 'Dez jogos com palpite registrado.',
                'tier' => 'bronze',
                'rule_type' => 'dez_palpites',
                'rule_metadata' => json_encode(['target' => 10]),
                'sort_order' => 11,
                'is_trackable' => true,
            ],
            [
                'slug' => 'meia-centuria',
                'name' => 'Meia Centúria',
                'description' => 'Cinquenta palpites — veterano do bolão.',
                'tier' => 'gold',
                'rule_type' => 'meia_centuria',
                'rule_metadata' => json_encode(['target' => 50]),
                'sort_order' => 12,
                'is_trackable' => true,
            ],
            [
                'slug' => 'maratonista',
                'name' => 'Maratonista',
                'description' => 'Dez dias de jogos com pelo menos um palpite.',
                'tier' => 'silver',
                'rule_type' => 'maratonista',
                'rule_metadata' => json_encode(['target' => 10]),
                'sort_order' => 13,
                'is_trackable' => true,
            ],
            [
                'slug' => 'fase-grupos-firme',
                'name' => 'Fase de Grupos Firme',
                'description' => 'Palpitou em todos os jogos de grupos que ainda estavam abertos quando você começou.',
                'tier' => 'gold',
                'rule_type' => 'fase_grupos_firme',
                'rule_metadata' => json_encode(['min_open_matches' => 8]),
                'sort_order' => 14,
                'is_trackable' => true,
            ],
            [
                'slug' => 'mata-mata-chegou',
                'name' => 'Mata-mata Chegou',
                'description' => 'Primeiro palpite em jogo de mata-mata.',
                'tier' => 'bronze',
                'rule_type' => 'mata_mata_chegou',
                'rule_metadata' => null,
                'sort_order' => 15,
                'is_trackable' => false,
            ],
            [
                'slug' => 'artilheiro-de-acertos',
                'name' => 'Artilheiro de Acertos',
                'description' => 'Dez placares exatos no bolão.',
                'tier' => 'gold',
                'rule_type' => 'artilheiro_de_acertos',
                'rule_metadata' => json_encode(['target' => 10]),
                'sort_order' => 16,
                'is_trackable' => true,
            ],
            [
                'slug' => 'sequencia-de-resultado',
                'name' => 'Sequência de Resultado',
                'description' => 'Acertou o resultado (vitória ou empate) em 5 jogos seguidos no tempo.',
                'tier' => 'silver',
                'rule_type' => 'sequencia_de_resultado',
                'rule_metadata' => json_encode(['target' => 5]),
                'sort_order' => 17,
                'is_trackable' => true,
            ],
            [
                'slug' => 'dupla-exata',
                'name' => 'Dupla Exata',
                'description' => 'Dois placares exatos seguidos (por ordem de kickoff).',
                'tier' => 'silver',
                'rule_type' => 'dupla_exata',
                'rule_metadata' => null,
                'sort_order' => 18,
                'is_trackable' => false,
            ],
            [
                'slug' => 'empate-certeiro',
                'name' => 'Empate Certeiro',
                'description' => 'Previu empate e o jogo terminou empatado (vale 1 ou 2 pts).',
                'tier' => 'bronze',
                'rule_type' => 'empate_certeiro',
                'rule_metadata' => null,
                'sort_order' => 19,
                'is_trackable' => false,
            ],
            [
                'slug' => 'zerinho',
                'name' => 'Zerinho',
                'description' => 'Palpitou 0x0 e saiu 0x0 (placar exato).',
                'tier' => 'silver',
                'rule_type' => 'zerinho',
                'rule_metadata' => null,
                'sort_order' => 20,
                'is_trackable' => false,
            ],
            [
                'slug' => 'goleada-prevista',
                'name' => 'Goleada Prevista',
                'description' => 'Acertou placar exato com soma de gols ≥ 5 no jogo.',
                'tier' => 'gold',
                'rule_type' => 'goleada_prevista',
                'rule_metadata' => json_encode(['min_total_goals' => 5]),
                'sort_order' => 21,
                'is_trackable' => false,
            ],
            [
                'slug' => 'top-10',
                'name' => 'Top 10',
                'description' => 'Entrou entre os dez primeiros do ranking.',
                'tier' => 'silver',
                'rule_type' => 'top_10',
                'rule_metadata' => null,
                'sort_order' => 22,
                'is_trackable' => false,
            ],
            [
                'slug' => 'vice-campeao',
                'name' => 'Vice do Bolão',
                'description' => 'Terminou a Copa em 2º no ranking (fechamento oficial).',
                'tier' => 'gold',
                'rule_type' => 'vice_campeao',
                'rule_metadata' => json_encode(['min_scored_predictions' => 20]),
                'sort_order' => 23,
                'is_trackable' => false,
            ],
            [
                'slug' => 'campeao-do-bolao',
                'name' => 'Campeão do Bolão',
                'description' => '1º lugar no ranking final da Copa.',
                'tier' => 'legendary',
                'rule_type' => 'campeao_do_bolao',
                'rule_metadata' => json_encode(['min_scored_predictions' => 20]),
                'sort_order' => 24,
                'is_trackable' => false,
            ],
            [
                'slug' => 'recuperacao',
                'name' => 'Recuperação',
                'description' => 'Subiu pelo menos 5 posições no ranking entre duas atualizações consecutivas.',
                'tier' => 'silver',
                'rule_type' => 'recuperacao',
                'rule_metadata' => json_encode(['min_jump' => 5]),
                'sort_order' => 25,
                'is_trackable' => false,
            ],
            [
                'slug' => 'semana-ativa',
                'name' => 'Semana Ativa',
                'description' => 'Palpitou em pelo menos um jogo em 7 dias corridos diferentes.',
                'tier' => 'silver',
                'rule_type' => 'semana_ativa',
                'rule_metadata' => json_encode(['target' => 7]),
                'sort_order' => 26,
                'is_trackable' => true,
            ],
            [
                'slug' => 'sem-miss-no-fds',
                'name' => 'Fim de Semana Completo',
                'description' => 'Palpitou em todos os jogos de um fim de semana (sáb+dom UTC) que ainda estavam abertos.',
                'tier' => 'gold',
                'rule_type' => 'sem_miss_no_fds',
                'rule_metadata' => json_encode(['min_matches' => 4]),
                'sort_order' => 27,
                'is_trackable' => false,
            ],
            [
                'slug' => 'estreia-da-copa',
                'name' => 'Estreia da Copa',
                'description' => 'Palpitou no jogo de abertura da Copa.',
                'tier' => 'bronze',
                'rule_type' => 'estreia_da_copa',
                'rule_metadata' => null,
                'sort_order' => 28,
                'is_trackable' => false,
            ],
            [
                'slug' => 'jogo-decisivo',
                'name' => 'Jogo Decisivo',
                'description' => 'Palpitou em uma semifinal ou jogo configurado como decisivo.',
                'tier' => 'silver',
                'rule_type' => 'jogo_decisivo',
                'rule_metadata' => null,
                'sort_order' => 29,
                'is_trackable' => false,
            ],
            [
                'slug' => 'grande-final',
                'name' => 'Grande Final',
                'description' => 'Enviou palpite na final da Copa.',
                'tier' => 'gold',
                'rule_type' => 'grande_final',
                'rule_metadata' => null,
                'sort_order' => 30,
                'is_trackable' => false,
            ],
            [
                'slug' => 'underdog-do-dia',
                'name' => 'Underdog do Dia',
                'description' => 'Acertou vitória do visitante quando o mandante era favorito.',
                'tier' => 'silver',
                'rule_type' => 'underdog_do_dia',
                'rule_metadata' => null,
                'sort_order' => 31,
                'is_trackable' => false,
            ],
            [
                'slug' => 'oraculo',
                'name' => 'Oráculo',
                'description' => 'Quinze placares exatos na mesma Copa — raríssimo.',
                'tier' => 'legendary',
                'rule_type' => 'oraculo',
                'rule_metadata' => json_encode(['target' => 15]),
                'sort_order' => 32,
                'is_trackable' => true,
            ],
            [
                'slug' => 'invicto-no-topo',
                'name' => 'Invicto no Topo',
                'description' => 'Ficou 5 atualizações de ranking seguidas em 1º lugar.',
                'tier' => 'legendary',
                'rule_type' => 'invicto_no_topo',
                'rule_metadata' => json_encode(['target' => 5]),
                'sort_order' => 33,
                'is_trackable' => true,
            ],
        ];
    }
};
