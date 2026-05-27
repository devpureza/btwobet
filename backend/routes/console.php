<?php

use App\Models\FootballMatch;
use App\Models\Team;
use App\Support\WorldCupTeamNames;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schedule;
use Illuminate\Support\Str;

Schedule::command('worldcup:sync-scores')
    ->everyThirtyMinutes()
    ->withoutOverlapping(25)
    ->runInBackground();

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('worldcup:import-openfootball {--url=https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json}', function () {
    $url = (string) $this->option('url');

    $this->info("Baixando tabela de jogos: {$url}");
    $response = Http::timeout(20)->get($url);
    $response->throw();
    $payload = $response->json();

    $matches = $payload['matches'] ?? null;
    if (!is_array($matches)) {
        $this->error('Formato inválido: payload.matches não é um array.');
        return self::FAILURE;
    }

    $this->warn('Isso vai substituir times e jogos atuais (predições serão apagadas por cascade).');
    Team::query()->delete();

    $codeForName = function (string $name): string {
        $ascii = Str::of($name)->ascii()->upper()->replaceMatches('/[^A-Z0-9 ]/', ' ')->squish()->toString();
        $parts = preg_split('/\s+/', $ascii) ?: [];
        $letters = '';
        foreach ($parts as $p) {
            if ($p === '') {
                continue;
            }
            $letters .= $p[0];
            if (strlen($letters) >= 3) {
                break;
            }
        }
        if (strlen($letters) < 3) {
            $letters = substr(str_pad(str_replace(' ', '', $ascii), 3, 'X'), 0, 3);
        }
        $base = substr($letters, 0, 3);
        $code = $base;

        $salt = 0;
        while (Team::where('code', $code)->exists()) {
            $salt++;
            $hash = strtoupper(substr(md5($name.'|'.$salt), 0, 1));
            $code = substr($base, 0, 2).$hash;
            if ($salt > 100) {
                $code = strtoupper(substr(md5($name), 0, 3));
                break;
            }
        }

        return $code;
    };

    $flagForTeamName = function (string $englishName): ?string {
        $iso2 = WorldCupTeamNames::ISO2[$englishName] ?? null;
        if (! $iso2) {
            return null;
        }

        return WorldCupTeamNames::flagCdnUrl($iso2);
    };

    $parseKickoff = function (string $date, string $time): ?\DateTimeImmutable {
        $date = trim($date);
        $time = trim($time);
        if ($date === '') {
            return null;
        }
        if ($time === '') {
            return new \DateTimeImmutable($date.' 12:00:00', new \DateTimeZone('UTC'));
        }
        if (preg_match('/^(\d{1,2}):(\d{2})\s*UTC([+-]\d+)/i', $time, $m)) {
            $sign = $m[3][0] === '-' ? '-' : '+';
            $hours = (int) substr($m[3], 1);
            $tz = new \DateTimeZone(sprintf('%s%02d:00', $sign, $hours));

            return (new \DateTimeImmutable(
                sprintf('%s %02d:%02d:00', $date, (int) $m[1], (int) $m[2]),
                $tz,
            ))->setTimezone(new \DateTimeZone('UTC'));
        }

        try {
            return new \DateTimeImmutable($date.' '.$time, new \DateTimeZone('UTC'));
        } catch (\Throwable) {
            return null;
        }
    };

    $teamIdByName = [];
    foreach ($matches as $m) {
        $t1 = (string) ($m['team1'] ?? '');
        $t2 = (string) ($m['team2'] ?? '');
        foreach ([$t1, $t2] as $t) {
            if ($t === '') {
                continue;
            }
            if (isset($teamIdByName[$t])) {
                continue;
            }
            $code = $codeForName($t);
            $groupRaw = isset($m['group']) ? (string) $m['group'] : null;
            $groupLetter = null;
            if ($groupRaw) {
                $groupLetter = strtoupper(substr(trim($groupRaw), -1));
                if (!preg_match('/^[A-Z]$/', $groupLetter)) {
                    $groupLetter = null;
                }
            }

            $team = Team::create([
                'code' => $code,
                'name' => WorldCupTeamNames::toPortuguese($t),
                'group_name' => $groupLetter,
                'flag_url' => $flagForTeamName($t),
            ]);
            $teamIdByName[$t] = $team->id;
        }
    }

    $imported = 0;
    foreach ($matches as $m) {
        $date = (string) ($m['date'] ?? '');
        $time = (string) ($m['time'] ?? '');
        $dt = $parseKickoff($date, $time);
        if (! $dt) {
            continue;
        }

        $round = Str::lower((string) ($m['round'] ?? 'group'));
        $group = isset($m['group']) ? (string) $m['group'] : null;
        $isKnockout = Str::contains($round, 'final')
            || Str::contains($round, 'semi')
            || Str::contains($round, 'quarter')
            || Str::contains($round, 'round of');

        FootballMatch::create([
            'home_team_id' => $teamIdByName[(string) $m['team1']],
            'away_team_id' => $teamIdByName[(string) $m['team2']],
            'kickoff_at' => $dt->format('Y-m-d H:i:s'),
            'stage' => $isKnockout ? 'knockout' : 'group',
            'group_name' => $group ? strtoupper(substr($group, -1)) : null,
            'venue' => isset($m['ground']) ? (string) $m['ground'] : null,
            'status' => 'scheduled',
            'home_score' => null,
            'away_score' => null,
        ]);
        $imported++;
    }

    $this->info("Import concluído: {$imported} jogos, ".Team::count().' seleções.');
    return self::SUCCESS;
})->purpose('Importa tabela de jogos (openfootball) para o banco');
