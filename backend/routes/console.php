<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use App\Models\FootballMatch;
use App\Models\Team;

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

    $flagForTeamName = function (string $name): ?string {
        $map = [
            'Mexico' => 'mx',
            'Canada' => 'ca',
            'USA' => 'us',
            'United States' => 'us',
            'Brazil' => 'br',
            'Argentina' => 'ar',
            'Colombia' => 'co',
            'Chile' => 'cl',
            'France' => 'fr',
            'Germany' => 'de',
            'Spain' => 'es',
            'Portugal' => 'pt',
            'England' => 'gb-eng',
            'Netherlands' => 'nl',
            'Italy' => 'it',
            'Belgium' => 'be',
            'Switzerland' => 'ch',
            'Morocco' => 'ma',
            'Uruguay' => 'uy',
            'Australia' => 'au',
            'Turkey' => 'tr',
            'Qatar' => 'qa',
            'Japan' => 'jp',
            'South Korea' => 'kr',
            'South Africa' => 'za',
            'Czech Republic' => 'cz',
            'Scotland' => 'gb-sct',
            'Ghana' => 'gh',
            'Panama' => 'pa',
            'Ecuador' => 'ec',
            'Tunisia' => 'tn',
            'Sweden' => 'se',
            'Norway' => 'no',
            'Egypt' => 'eg',
            'Iran' => 'ir',
            'New Zealand' => 'nz',
            'Saudi Arabia' => 'sa',
            'Cape Verde' => 'cv',
            'Iraq' => 'iq',
            'Senegal' => 'sn',
            'Algeria' => 'dz',
            'Austria' => 'at',
            'Jordan' => 'jo',
            'Paraguay' => 'py',
            'Bosnia & Herzegovina' => 'ba',
        ];

        $code = $map[$name] ?? null;
        if (!$code) {
            return null;
        }
        return '/flags/'.$code.'.png';
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
                'name' => $t,
                'group_name' => $groupLetter,
                'flag_url' => $flagForTeamName($t),
            ]);
            $teamIdByName[$t] = $team->id;
        }
    }

    foreach ($matches as $m) {
        $date = (string) ($m['date'] ?? '');
        $time = (string) ($m['time'] ?? '');
        $kickoffAt = trim($date.' '.$time);
        if ($kickoffAt === '') {
            continue;
        }

        $dt = new DateTimeImmutable($kickoffAt);
        $round = (string) ($m['round'] ?? 'group');
        $group = isset($m['group']) ? (string) $m['group'] : null;

        FootballMatch::create([
            'home_team_id' => $teamIdByName[(string) $m['team1']],
            'away_team_id' => $teamIdByName[(string) $m['team2']],
            'kickoff_at' => $dt->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d H:i:s'),
            'stage' => Str::contains(Str::lower($round), 'round') || Str::contains(Str::lower($round), 'final') ? 'knockout' : 'group',
            'group_name' => $group ? substr($group, -1) : null,
            'venue' => isset($m['ground']) ? (string) $m['ground'] : null,
            'status' => 'scheduled',
            'home_score' => null,
            'away_score' => null,
        ]);
    }

    $this->info('Import concluído.');
    return self::SUCCESS;
})->purpose('Importa tabela de jogos (openfootball) para o banco');
