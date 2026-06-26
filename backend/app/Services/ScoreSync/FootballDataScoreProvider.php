<?php

namespace App\Services\ScoreSync;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FootballDataScoreProvider
{
    /**
     * @return list<array{
     *   home_name: string,
     *   away_name: string,
     *   kickoff_at: Carbon,
     *   home_score: int|null,
     *   away_score: int|null,
     *   started: bool,
     *   finished: bool,
     *   external_id: int|null
     * }>
     */
    public function fetch(): array
    {
        $url = (string) config('services.football_data.api_url');
        $token = (string) config('services.football_data.api_token');

        if (empty($token)) {
            Log::warning('football_data.sync.no_token');
            return [];
        }

        $response = Http::timeout(25)
            ->withHeaders([
                'X-Auth-Token' => $token,
                'Accept' => 'application/json',
            ])
            ->get($url);

        if (! $response->successful()) {
            Log::warning('football_data.sync.http_failed', [
                'url' => $url,
                'status' => $response->status(),
            ]);

            return [];
        }

        $payload = $response->json();
        $rawGames = $payload['matches'] ?? [];

        $parsed = [];
        foreach ($rawGames as $game) {
            $item = $this->mapGame($game);
            if ($item === null) {
                continue;
            }
            $key = $item['home_name'].'|'.$item['away_name'].'|'.$item['kickoff_at']->format('Y-m-d H:i');
            $parsed[$key] = $item;
        }

        return array_values($parsed);
    }

    /**
     * @param  array<string, mixed>  $game
     * @return array{
     *   home_name: string,
     *   away_name: string,
     *   kickoff_at: Carbon,
     *   home_score: int|null,
     *   away_score: int|null,
     *   started: bool,
     *   finished: bool,
     *   external_id: int|null
     * }|null
     */
    private function mapGame(array $game): ?array
    {
        $homeTeam = $game['homeTeam'] ?? null;
        $awayTeam = $game['awayTeam'] ?? null;
        if (! is_array($homeTeam) || ! is_array($awayTeam)) {
            return null;
        }

        $home = trim((string) (($homeTeam['shortName'] ?? '') ?: ($homeTeam['name'] ?? '')));
        $away = trim((string) (($awayTeam['shortName'] ?? '') ?: ($awayTeam['name'] ?? '')));
        if ($home === '' || $away === '') {
            return null;
        }

        $kickoffRaw = (string) ($game['utcDate'] ?? '');
        if ($kickoffRaw === '') {
            return null;
        }

        try {
            $kickoff = Carbon::parse($kickoffRaw)->utc();
        } catch (\Throwable) {
            return null;
        }

        $homeScore = $game['score']['fullTime']['home'] ?? null;
        $awayScore = $game['score']['fullTime']['away'] ?? null;

        $status = strtoupper((string) ($game['status'] ?? ''));
        $started = in_array($status, ['IN_PLAY', 'PAUSED', 'FINISHED'], true);
        $finished = $status === 'FINISHED';

        return [
            'home_name' => $home,
            'away_name' => $away,
            'kickoff_at' => $kickoff,
            'home_score' => $homeScore !== null ? (int) $homeScore : null,
            'away_score' => $awayScore !== null ? (int) $awayScore : null,
            'started' => $started,
            'finished' => $finished,
            'external_id' => isset($game['id']) ? (int) $game['id'] : null,
        ];
    }

    public function fetchAll(): array
    {
        $url = (string) config('services.football_data.api_url');
        $token = (string) config('services.football_data.api_token');
        if (empty($token)) { Log::warning('football_data.bracket.no_token'); return []; }
        $response = Http::timeout(25)
            ->withHeaders(['X-Auth-Token' => $token, 'Accept' => 'application/json'])->get($url);
        if (! $response->successful()) {
            Log::warning('football_data.bracket.http_failed', ['status' => $response->status()]);
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
            try { $kickoff = Carbon::parse((string) $g['utcDate'])->utc(); }
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
}
