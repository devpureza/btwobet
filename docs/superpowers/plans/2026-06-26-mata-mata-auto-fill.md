# Auto-preenchimento do mata-mata — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preencher automaticamente os times reais do mata-mata espelhando o chaveamento que a API football-data.org já resolve, com override do admin e janela de palpite segura na virada.

**Architecture:** Adicionamos uma chave estável `external_id` (id do football-data) em `matches`, populada por um comando de backfill que casa por horário de início. O sync, a cada 5 min, espelha os times reais da API nos jogos correspondentes (via `external_id`), sem sobrescrever overrides manuais do admin. `TeamSlot` passa a reconhecer placeholders `W{n}`/`L{n}`, e o `PredictionWindow` garante janela mínima quando os times definem em cima da hora.

**Tech Stack:** Laravel 11 / PHP 8.4, PostgreSQL, PHPUnit (`php artisan test`), Flutter (admin UI).

## Global Constraints

- **Banco de produção é intocável.** Toda migration deve ser **aditiva** (colunas novas nullable); nada de drop/alter-lossy/`migrate:fresh`. Push em `main` roda `migrate --force` no prod.
- Comandos rodam no container: `docker compose exec -T app php artisan ...`. Testes: `docker compose exec -T app php artisan test`.
- Reusar `TeamNameMatcher` (já resolve inglês↔PT) e padrões existentes; não criar 2ª arquitetura de matching.
- Stage interno: `'group'` | `'knockout'`. Stages da API: `GROUP_STAGE` → `group`; qualquer outro (`LAST_32`, `LAST_16`, `QUARTER_FINALS`, `SEMI_FINALS`, `THIRD_PLACE`, `FINAL`) → `knockout`.

---

### Task 1: Migration aditiva + model

**Files:**
- Create: `backend/database/migrations/2026_06_26_000001_add_bracket_fields_to_matches.php`
- Modify: `backend/app/Models/FootballMatch.php:14-36` (fillable + casts)
- Test: `backend/tests/Feature/BracketFieldsMigrationTest.php`

**Interfaces:**
- Produces: colunas `matches.external_id` (nullable, unique, bigint), `matches.teams_locked` (bool, default false), `matches.teams_defined_at` (timestamp nullable). `FootballMatch` aceita esses campos em `fill()` e casta `teams_locked`→bool, `teams_defined_at`→datetime.

- [ ] **Step 1: Write the failing test**

```php
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=BracketFieldsMigrationTest`
Expected: FAIL (column/cast não existe).

- [ ] **Step 3: Write the migration**

```php
<?php // backend/database/migrations/2026_06_26_000001_add_bracket_fields_to_matches.php
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
```

- [ ] **Step 4: Update the model**

In `backend/app/Models/FootballMatch.php`, add to `$fillable` (after `'home_score', 'away_score',`): `'external_id', 'teams_locked', 'teams_defined_at',`. In `casts()` add: `'teams_locked' => 'boolean', 'teams_defined_at' => 'datetime', 'external_id' => 'integer',`.

- [ ] **Step 5: Run test to verify it passes**

Run: `docker compose exec -T app php artisan migrate --force && docker compose exec -T app php artisan test --filter=BracketFieldsMigrationTest`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/database/migrations/2026_06_26_000001_add_bracket_fields_to_matches.php backend/app/Models/FootballMatch.php backend/tests/Feature/BracketFieldsMigrationTest.php
git commit -m "feat(bracket): colunas aditivas external_id/teams_locked/teams_defined_at"
```

---

### Task 2: TeamSlot reconhece W{n}/L{n}

**Files:**
- Modify: `backend/app/Support/TeamSlot.php:44-57`
- Test: `backend/tests/Unit/TeamSlotTest.php`

**Interfaces:**
- Produces: `TeamSlot::looksLikeSlot('W73') === true`, `looksLikeSlot('L101') === true`, `looksLikeSlot('Brasil') === false`.

- [ ] **Step 1: Write the failing test**

```php
<?php // backend/tests/Unit/TeamSlotTest.php
namespace Tests\Unit;
use App\Support\TeamSlot;
use PHPUnit\Framework\TestCase;

class TeamSlotTest extends TestCase
{
    public function test_winner_loser_slots_are_placeholders(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('W73'));
        $this->assertTrue(TeamSlot::looksLikeSlot('L101'));
        $this->assertTrue(TeamSlot::looksLikeSlot('w12'));
    }

    public function test_group_slots_still_work_and_real_names_dont(): void
    {
        $this->assertTrue(TeamSlot::looksLikeSlot('2A'));
        $this->assertTrue(TeamSlot::looksLikeSlot('3A/B/C/D/F'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Brasil'));
        $this->assertFalse(TeamSlot::looksLikeSlot('Wales')); // não confundir W+letras
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=TeamSlotTest`
Expected: FAIL em `W73`/`L101`.

- [ ] **Step 3: Add the regex**

In `backend/app/Support/TeamSlot.php`, dentro de `looksLikeSlot`, antes do `return false;`:

```php
        // Vencedor/perdedor do jogo N (football-data: W73, L101).
        if (preg_match('/^[WL]\d+$/i', $value)) {
            return true;
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=TeamSlotTest`
Expected: PASS (`Wales` continua false porque tem letras, não dígitos).

- [ ] **Step 5: Commit**

```bash
git add backend/app/Support/TeamSlot.php backend/tests/Unit/TeamSlotTest.php
git commit -m "feat(bracket): TeamSlot reconhece placeholders W{n}/L{n}"
```

---

### Task 3: Provider expõe dados do chaveamento (`fetchAll`)

**Files:**
- Modify: `backend/app/Services/ScoreSync/FootballDataScoreProvider.php`
- Test: `backend/tests/Unit/FootballDataFetchAllTest.php`

**Interfaces:**
- Produces: `FootballDataScoreProvider::parseAll(array $payload): list<array{external_id:int, stage:string, home_name:?string, away_name:?string, kickoff_at:Carbon}>`. `stage` já mapeado para `'group'`/`'knockout'`. `home_name`/`away_name` são `null` quando a API ainda não definiu o time (placeholder). Não dropa jogos indefinidos. `fetch()` (placares) permanece inalterado.

- [ ] **Step 1: Write the failing test**

```php
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=FootballDataFetchAllTest`
Expected: FAIL (`parseAll` não existe).

- [ ] **Step 3: Implement `parseAll` + `fetchAll`**

Add to `FootballDataScoreProvider`:

```php
    public function fetchAll(): array
    {
        $url = (string) config('services.football_data.api_url');
        $token = (string) config('services.football_data.api_token');
        if (empty($token)) { \Illuminate\Support\Facades\Log::warning('football_data.bracket.no_token'); return []; }
        $response = \Illuminate\Support\Facades\Http::timeout(25)
            ->withHeaders(['X-Auth-Token' => $token, 'Accept' => 'application/json'])->get($url);
        if (! $response->successful()) {
            \Illuminate\Support\Facades\Log::warning('football_data.bracket.http_failed', ['status' => $response->status()]);
            return [];
        }
        return $this->parseAll($response->json());
    }

    /** @return list<array{external_id:int, stage:string, home_name:?string, away_name:?string, kickoff_at:\Carbon\Carbon}> */
    public function parseAll(array $payload): array
    {
        $out = [];
        foreach (($payload['matches'] ?? []) as $g) {
            if (! isset($g['id'], $g['utcDate'])) { continue; }
            try { $kickoff = \Carbon\Carbon::parse((string) $g['utcDate'])->utc(); }
            catch (\Throwable) { continue; }
            $stage = strtoupper((string) ($g['stage'] ?? '')) === 'GROUP_STAGE' ? 'group' : 'knockout';
            $out[] = [
                'external_id' => (int) $g['id'],
                'stage' => $stage,
                'home_name' => $this->teamName($g['homeTeam'] ?? null),
                'away_name' => $this->teamName($g['awayTeam'] ?? null),
                'kickoff_at' => $kickoff,
            ];
        }
        return $out;
    }

    private function teamName(?array $team): ?string
    {
        if (! is_array($team)) { return null; }
        $name = trim((string) (($team['shortName'] ?? '') ?: ($team['name'] ?? '')));
        return $name === '' ? null : $name;
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=FootballDataFetchAllTest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/Services/ScoreSync/FootballDataScoreProvider.php backend/tests/Unit/FootballDataFetchAllTest.php
git commit -m "feat(bracket): provider expõe fetchAll com external_id e stage"
```

---

### Task 4: Comando de backfill `worldcup:link-external-ids`

**Files:**
- Create: `backend/app/Console/Commands/LinkExternalIds.php`
- Test: `backend/tests/Feature/LinkExternalIdsTest.php`

**Interfaces:**
- Consumes: `FootballDataScoreProvider::fetchAll()`, `TeamNameMatcher::findTeam()`.
- Produces: `php artisan worldcup:link-external-ids` → para cada jogo da API, acha o jogo local por **kickoff_at (minuto)** (desempate por times quando há jogos simultâneos), grava `external_id`, e quando o stage da API é `knockout` mas o local é `group` (3º lugar mal-rotulado), corrige `stage='knockout'`. Idempotente. Loga órfãos.

- [ ] **Step 1: Write the failing test**

```php
<?php // backend/tests/Feature/LinkExternalIdsTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\ScoreSync\FootballDataScoreProvider;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LinkExternalIdsTest extends TestCase
{
    use RefreshDatabase;

    public function test_links_by_kickoff_and_fixes_third_place_stage(): void
    {
        $ph = Team::create(['code' => 'L101', 'name' => 'L101']);
        $thirdPlace = FootballMatch::create([
            'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-07-18T21:00:00Z', 'stage' => 'group', 'status' => 'scheduled',
        ]);

        $this->mock(FootballDataScoreProvider::class, function ($m) {
            $m->shouldReceive('fetchAll')->andReturn([[
                'external_id' => 111222, 'stage' => 'knockout',
                'home_name' => null, 'away_name' => null,
                'kickoff_at' => Carbon::parse('2026-07-18T21:00:00Z'),
            ]]);
        });

        $this->artisan('worldcup:link-external-ids')->assertExitCode(0);

        $thirdPlace->refresh();
        $this->assertSame(111222, $thirdPlace->external_id);
        $this->assertSame('knockout', $thirdPlace->stage);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=LinkExternalIdsTest`
Expected: FAIL (comando não existe).

- [ ] **Step 3: Implement the command**

```php
<?php // backend/app/Console/Commands/LinkExternalIds.php
namespace App\Console\Commands;
use App\Models\FootballMatch;
use App\Services\ScoreSync\FootballDataScoreProvider;
use App\Support\TeamNameMatcher;
use Illuminate\Console\Command;

class LinkExternalIds extends Command
{
    protected $signature = 'worldcup:link-external-ids';
    protected $description = 'Liga matches locais aos jogos do football-data (external_id) por horário, reconciliando stage.';

    public function handle(FootballDataScoreProvider $provider): int
    {
        TeamNameMatcher::resetIndex();
        $apiGames = $provider->fetchAll();
        $orphans = [];

        foreach ($apiGames as $g) {
            $candidates = FootballMatch::query()
                ->whereRaw("date_trunc('minute', kickoff_at) = date_trunc('minute', ?::timestamptz)", [$g['kickoff_at']->toIso8601String()])
                ->get();

            $match = $this->disambiguate($candidates, $g);
            if (! $match) { $orphans[] = $g['external_id'].' @ '.$g['kickoff_at']->toIso8601String(); continue; }

            $dirty = false;
            if ($match->external_id !== $g['external_id']) { $match->external_id = $g['external_id']; $dirty = true; }
            if ($g['stage'] === 'knockout' && $match->stage !== 'knockout') { $match->stage = 'knockout'; $dirty = true; }
            if ($dirty) { $match->save(); }
        }

        if ($orphans !== []) { $this->warn('Órfãos (API sem par local): '.implode(', ', array_slice($orphans, 0, 20))); }
        $this->info('Linkados: '.FootballMatch::whereNotNull('external_id')->count().' jogos.');
        return self::SUCCESS;
    }

    /** @param \Illuminate\Support\Collection<int,FootballMatch> $candidates */
    private function disambiguate($candidates, array $g): ?FootballMatch
    {
        if ($candidates->count() <= 1) { return $candidates->first(); }
        // Jogos simultâneos (rodada final de grupos): desempata por times reais.
        $home = $g['home_name'] ? TeamNameMatcher::findTeam($g['home_name']) : null;
        $away = $g['away_name'] ? TeamNameMatcher::findTeam($g['away_name']) : null;
        if ($home && $away) {
            $exact = $candidates->first(fn (FootballMatch $m) => $m->home_team_id === $home->id && $m->away_team_id === $away->id);
            if ($exact) { return $exact; }
        }
        return $candidates->firstWhere('external_id', null) ?? $candidates->first();
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=LinkExternalIdsTest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/Console/Commands/LinkExternalIds.php backend/tests/Feature/LinkExternalIdsTest.php
git commit -m "feat(bracket): comando link-external-ids com reconciliação do 3º lugar"
```

---

### Task 5: Espelhamento dos times no sync

**Files:**
- Modify: `backend/app/Services/WorldCupScoreSyncService.php`
- Test: `backend/tests/Feature/BracketTeamMirrorTest.php`

**Interfaces:**
- Consumes: `FootballDataScoreProvider::fetchAll()`, `TeamNameMatcher::findTeam()`, `TeamSlot::isPlaceholder()`, `matches.external_id` (Task 1/4).
- Produces: `WorldCupScoreSyncService::mirrorBracketTeams(): array{filled:int}`. Para cada jogo da API com ambos os nomes resolvíveis a times reais, acha o match local por `external_id`; se o slot local ainda é placeholder e `teams_locked=false`, seta `home_team_id`/`away_team_id`; quando os dois ficam definidos, grava `teams_defined_at`. Chamado dentro de `syncFromGloboEsporte()` antes do loop de placares.

- [ ] **Step 1: Write the failing test**

```php
<?php // backend/tests/Feature/BracketTeamMirrorTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\ScoreSync\FootballDataScoreProvider;
use App\Services\WorldCupScoreSyncService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BracketTeamMirrorTest extends TestCase
{
    use RefreshDatabase;

    public function test_fills_placeholder_with_real_team_but_not_when_locked(): void
    {
        $ph = Team::create(['code' => '2A', 'name' => '2A']);
        $bra = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        $jpn = Team::create(['code' => 'JPN', 'name' => 'Japan']);

        $open = FootballMatch::create(['external_id' => 500, 'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-06-29T17:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled', 'teams_locked' => false]);
        $locked = FootballMatch::create(['external_id' => 501, 'home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-06-29T20:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled', 'teams_locked' => true]);

        $this->mock(FootballDataScoreProvider::class, function ($m) {
            $m->shouldReceive('fetchAll')->andReturn([
                ['external_id' => 500, 'stage' => 'knockout', 'home_name' => 'Brazil', 'away_name' => 'Japan', 'kickoff_at' => Carbon::parse('2026-06-29T17:00:00Z')],
                ['external_id' => 501, 'stage' => 'knockout', 'home_name' => 'Brazil', 'away_name' => 'Japan', 'kickoff_at' => Carbon::parse('2026-06-29T20:00:00Z')],
            ]);
        });

        $res = app(WorldCupScoreSyncService::class)->mirrorBracketTeams();

        $this->assertSame(1, $res['filled']);
        $open->refresh(); $locked->refresh();
        $this->assertSame($bra->id, $open->home_team_id);
        $this->assertSame($jpn->id, $open->away_team_id);
        $this->assertNotNull($open->teams_defined_at);
        $this->assertSame($ph->id, $locked->home_team_id); // lock respeitado
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=BracketTeamMirrorTest`
Expected: FAIL (`mirrorBracketTeams` não existe).

- [ ] **Step 3: Implement `mirrorBracketTeams` and call it in the sync**

Add `use App\Support\TeamSlot;` ao topo. Adicione o método e chame-o no início de `syncFromGloboEsporte()` (logo após `TeamNameMatcher::resetIndex();`): `$this->mirrorBracketTeams();`.

```php
    /** @return array{filled:int} */
    public function mirrorBracketTeams(): array
    {
        TeamNameMatcher::resetIndex();
        $filled = 0;
        foreach ($this->globo->fetchAll() as $g) {
            if ($g['home_name'] === null || $g['away_name'] === null) { continue; }
            $home = TeamNameMatcher::findTeam($g['home_name']);
            $away = TeamNameMatcher::findTeam($g['away_name']);
            if (! $home || ! $away || TeamSlot::isPlaceholder($home) || TeamSlot::isPlaceholder($away)) { continue; }

            $match = FootballMatch::where('external_id', $g['external_id'])->first();
            if (! $match || $match->teams_locked) { continue; }
            $match->loadMissing(['homeTeam', 'awayTeam']);

            $changed = false;
            if (TeamSlot::isPlaceholder($match->homeTeam) && $match->home_team_id !== $home->id) {
                $match->home_team_id = $home->id; $match->setRelation('homeTeam', $home); $changed = true;
            }
            if (TeamSlot::isPlaceholder($match->awayTeam) && $match->away_team_id !== $away->id) {
                $match->away_team_id = $away->id; $match->setRelation('awayTeam', $away); $changed = true;
            }
            if ($changed) {
                if (! TeamSlot::isPlaceholder($match->homeTeam) && ! TeamSlot::isPlaceholder($match->awayTeam) && $match->teams_defined_at === null) {
                    $match->teams_defined_at = now();
                }
                $match->save();
                $filled++;
            }
        }
        return ['filled' => $filled];
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=BracketTeamMirrorTest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/Services/WorldCupScoreSyncService.php backend/tests/Feature/BracketTeamMirrorTest.php
git commit -m "feat(bracket): espelhamento automático dos times do mata-mata no sync"
```

---

### Task 6: Janela de palpite na definição tardia

**Files:**
- Modify: `backend/app/Services/PredictionWindow.php:100-111`
- Test: `backend/tests/Feature/PredictionWindowLateTest.php`

**Interfaces:**
- Consumes: `matches.teams_defined_at` (Task 1), `BolaoSettings::knockoutHoursBefore()`.
- Produces: const `PredictionWindow::LATE_DEFINE_MIN_HOURS = 3`. `deadlineForMatch` no knockout: se `teams_defined_at` é tarde (depois de `kickoff − knockoutHours`), retorna `kickoff − 3h`.

- [ ] **Step 1: Write the failing test**

```php
<?php // backend/tests/Feature/PredictionWindowLateTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Services\PredictionWindow;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PredictionWindowLateTest extends TestCase
{
    use RefreshDatabase;

    public function test_late_defined_knockout_opens_until_3h_before(): void
    {
        Carbon::setTestNow('2026-07-04T10:00:00Z');
        $t = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        // kickoff em 5h; prazo normal (kickoff-24h) já passou, mas times definidos agora.
        $m = FootballMatch::create(['home_team_id' => $t->id, 'away_team_id' => $t->id,
            'kickoff_at' => '2026-07-04T15:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled',
            'teams_defined_at' => '2026-07-04T09:00:00Z']);

        $deadline = app(PredictionWindow::class)->deadlineForMatch($m);
        $this->assertEquals(Carbon::parse('2026-07-04T12:00:00Z'), $deadline); // kickoff - 3h
        Carbon::setTestNow();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=PredictionWindowLateTest`
Expected: FAIL (retorna kickoff-24h, já passado).

- [ ] **Step 3: Implement the late window**

Add const ao topo da classe: `public const LATE_DEFINE_MIN_HOURS = 3;`. No `deadlineForMatch`, substitua o ramo `knockout`:

```php
        if ($match->stage === 'knockout') {
            $normal = $match->kickoff_at->copy()->subHours($this->settings->knockoutHoursBefore());
            $definedAt = $match->teams_defined_at;
            if ($definedAt !== null && $definedAt->gt($normal)) {
                // Times definidos tarde: garante janela mínima.
                return $match->kickoff_at->copy()->subHours(self::LATE_DEFINE_MIN_HOURS);
            }
            return $normal;
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=PredictionWindowLateTest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/Services/PredictionWindow.php backend/tests/Feature/PredictionWindowLateTest.php
git commit -m "feat(bracket): janela mínima de palpite quando times definem tarde"
```

---

### Task 7: Override do admin (endpoint)

**Files:**
- Modify: `backend/app/Http/Controllers/Api/Admin/MatchAdminController.php:89-113`
- Test: `backend/tests/Feature/AdminSetTeamsTest.php`

**Interfaces:**
- Consumes: `matches.teams_locked`, relação `homeTeam`/`awayTeam`.
- Produces: `PATCH /admin/matches/{id}` aceita `home_team_id` e `away_team_id` (`exists:teams,id`); ao setar qualquer um, marca `teams_locked = true` e (se ambos definidos) `teams_defined_at = now()`.

- [ ] **Step 1: Write the failing test**

```php
<?php // backend/tests/Feature/AdminSetTeamsTest.php
namespace Tests\Feature;
use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSetTeamsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_set_teams_and_locks(): void
    {
        $admin = User::factory()->create(['is_admin' => true, 'approval_status' => 'approved']);
        $ph = Team::create(['code' => 'W73', 'name' => 'W73']);
        $bra = Team::create(['code' => 'BRA', 'name' => 'Brazil']);
        $arg = Team::create(['code' => 'ARG', 'name' => 'Argentina']);
        $m = FootballMatch::create(['home_team_id' => $ph->id, 'away_team_id' => $ph->id,
            'kickoff_at' => '2026-07-09T20:00:00Z', 'stage' => 'knockout', 'status' => 'scheduled']);

        $this->actingAs($admin)->patchJson("/api/admin/matches/{$m->id}", [
            'home_team_id' => $bra->id, 'away_team_id' => $arg->id,
        ])->assertOk();

        $m->refresh();
        $this->assertSame($bra->id, $m->home_team_id);
        $this->assertSame($arg->id, $m->away_team_id);
        $this->assertTrue($m->teams_locked);
        $this->assertNotNull($m->teams_defined_at);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `docker compose exec -T app php artisan test --filter=AdminSetTeamsTest`
Expected: FAIL (campos ignorados pela validação).

- [ ] **Step 3: Extend the controller**

No `update()`, adicione à validação:

```php
            'home_team_id' => ['sometimes', 'integer', 'exists:teams,id'],
            'away_team_id' => ['sometimes', 'integer', 'exists:teams,id'],
```

Antes de `$match->fill($validated);`:

```php
        if (array_key_exists('home_team_id', $validated) || array_key_exists('away_team_id', $validated)) {
            $validated['teams_locked'] = true;
        }
```

Depois de `$match->fill($validated); $match->save();` (mas antes do `return`):

```php
        $match->loadMissing(['homeTeam', 'awayTeam']);
        if ($match->teams_defined_at === null
            && ! \App\Support\TeamSlot::isPlaceholder($match->homeTeam)
            && ! \App\Support\TeamSlot::isPlaceholder($match->awayTeam)) {
            $match->teams_defined_at = now();
            $match->save();
        }
```

> `teams_locked` está em `$fillable` (Task 1), então `$match->fill($validated)` aplica.

- [ ] **Step 4: Run test to verify it passes**

Run: `docker compose exec -T app php artisan test --filter=AdminSetTeamsTest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/app/Http/Controllers/Api/Admin/MatchAdminController.php backend/tests/Feature/AdminSetTeamsTest.php
git commit -m "feat(bracket): admin pode definir times do jogo (override + lock)"
```

---

### Task 8: UI admin — seletor de times

**Files:**
- Modify: `mobile/lib/features/admin/admin_matches_screen.dart` (diálogo de edição), `mobile/lib/features/admin/admin_repository.dart` (update aceita team ids).
- Test: verificação manual no app (o projeto não tem widget tests de admin; segue o padrão existente).

**Interfaces:**
- Consumes: lista de times (reutilize o fetch de teams do `admin_repository`), `PATCH /admin/matches/{id}` (Task 7).
- Produces: no diálogo de edição de jogo, dois `DropdownButtonFormField<int>` (mandante/visitante) populados com os times; ao salvar, envia `home_team_id`/`away_team_id` junto com os campos atuais.

- [ ] **Step 1: Ler os arquivos atuais**

Leia `mobile/lib/features/admin/admin_matches_screen.dart` e `admin_repository.dart` para localizar o diálogo de edição (hoje envia `kickoff_at`, `venue`, `stage`, `group_name`, `status`) e o método de repositório que chama `PATCH /admin/matches/{id}`.

- [ ] **Step 2: Estender o repositório**

No método de update do `admin_repository.dart`, adicione parâmetros opcionais `int? homeTeamId, int? awayTeamId` e inclua-os no corpo quando não-nulos:

```dart
if (homeTeamId != null) body['home_team_id'] = homeTeamId;
if (awayTeamId != null) body['away_team_id'] = awayTeamId;
```

- [ ] **Step 3: Adicionar os dropdowns no diálogo**

No diálogo de edição, carregue os times (reutilize o fetch de teams) e adicione dois `DropdownButtonFormField<int>` (mandante/visitante) inicializados com `match.home_team.id`/`away_team.id`. No salvar, passe os ids selecionados ao método do repositório.

- [ ] **Step 4: Verificar no app**

Run: `cd mobile && flutter analyze lib/features/admin/`
Expected: sem erros. Depois, manualmente no `localhost:5173` (admin), abrir um jogo do mata-mata placeholder, escolher os dois times, salvar, e confirmar que o card passa a mostrar os times e abre pra palpite.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/admin/admin_matches_screen.dart mobile/lib/features/admin/admin_repository.dart
git commit -m "feat(bracket): seletor de times no admin (override do chaveamento)"
```

---

### Task 9: Backfill no local espelhado + validação ponta-a-ponta

**Files:** nenhum (operacional).

- [ ] **Step 1:** `docker compose exec -T app php artisan worldcup:link-external-ids` → confirma "Linkados: N jogos" e nenhum órfão inesperado.
- [ ] **Step 2:** Forçar um ciclo de sync (descobrir o nome do comando de sync existente via `php artisan list | grep -i sync`) e conferir que os 16-avos já resolvidos pela API aparecem com times reais no app.
- [ ] **Step 3:** Conferir no app (`localhost:5173`) que jogos ainda indefinidos mostram "Aguardando definição dos times" (incl. os `W{n}`/`L{n}`, agora bloqueados) e que o 3º lugar virou knockout.

---

## Self-Review

**Cobertura do spec:** §1 external_id → T1/T4; §2 espelhamento → T5; §3 captura winner → **deferido** com a pontuação (YAGNI, documentado no spec §8); §4 TeamSlot → T2; §5 admin override → T7/T8; §6 janela tardia → T6; reconciliação 3º lugar → T4; provider → T3; validação → T9. ✅
**Placeholders:** nenhum TODO/TBD; código completo por step.
**Consistência de tipos:** `mirrorBracketTeams(): array{filled:int}`, `parseAll(): list<...>`, `fetchAll()`, `LATE_DEFINE_MIN_HOURS=3`, signature `worldcup:link-external-ids` — usados de forma consistente entre tasks.

**Observação:** o comando de sync que invoca `syncFromGloboEsporte()` (scheduler/console) não é alterado — `mirrorBracketTeams()` roda dentro dele. Confirmar o nome real do comando de sync ao executar a Task 9.
