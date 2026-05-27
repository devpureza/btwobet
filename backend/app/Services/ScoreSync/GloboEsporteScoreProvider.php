<?php

namespace App\Services\ScoreSync;

use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GloboEsporteScoreProvider
{
    /**
     * @return list<array{
     *   home_name: string,
     *   away_name: string,
     *   kickoff_at: Carbon,
     *   home_score: int|null,
     *   away_score: int|null,
     *   started: bool,
     *   external_id: int|null
     * }>
     */
    public function fetch(): array
    {
        $url = (string) config('services.globo_esporte.copa_url');

        $response = Http::timeout(25)
            ->withHeaders([
                'User-Agent' => 'Mozilla/5.0 (compatible; BTwoBet/1.0; +https://github.com/devpureza/btwobet)',
                'Accept' => 'text/html,application/xhtml+xml',
            ])
            ->get($url);

        if (! $response->successful()) {
            Log::warning('globo_esporte.sync.http_failed', [
                'url' => $url,
                'status' => $response->status(),
            ]);

            return [];
        }

        $html = $response->body();
        $payload = $this->extractClassificacaoJson($html);

        if ($payload === null) {
            Log::warning('globo_esporte.sync.no_classificacao', ['url' => $url]);

            return [];
        }

        return $this->parseGames($payload, $html);
    }

    /**
     * @return array<string, mixed>|null
     */
    private function extractClassificacaoJson(string $html): ?array
    {
        if (! preg_match('/const\s+classificacao\s*=\s*(\{)/', $html, $m, PREG_OFFSET_CAPTURE)) {
            return null;
        }

        $start = $m[1][1];
        $depth = 0;
        $len = strlen($html);

        for ($i = $start; $i < $len; $i++) {
            $char = $html[$i];
            if ($char === '{') {
                $depth++;
            } elseif ($char === '}') {
                $depth--;
                if ($depth === 0) {
                    $json = substr($html, $start, $i - $start + 1);
                    $decoded = json_decode($json, true);

                    return is_array($decoded) ? $decoded : null;
                }
            }
        }

        return null;
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return list<array{
     *   home_name: string,
     *   away_name: string,
     *   kickoff_at: Carbon,
     *   home_score: int|null,
     *   away_score: int|null,
     *   started: bool,
     *   external_id: int|null
     * }>
     */
    private function parseGames(array $payload, string $html): array
    {
        $rawGames = [];
        $this->collectListaJogos($payload, $rawGames);
        $this->collectListaJogosFromHtml($html, $rawGames);

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
     * @param  array<string, mixed>  $node
     * @param  list<array<string, mixed>>  $out
     */
    private function collectListaJogos(array $node, array &$out): void
    {
        if (isset($node['lista_jogos']) && is_array($node['lista_jogos'])) {
            foreach ($node['lista_jogos'] as $game) {
                if (is_array($game) && isset($game['equipes'])) {
                    $out[] = $game;
                }
            }
        }

        foreach ($node as $value) {
            if (is_array($value)) {
                $this->collectListaJogos($value, $out);
            }
        }
    }

    /**
     * @param  list<array<string, mixed>>  $out
     */
    private function collectListaJogosFromHtml(string $html, array &$out): void
    {
        if (! preg_match_all('/"lista_jogos"\s*:\s*\[/', $html, $matches, PREG_OFFSET_CAPTURE)) {
            return;
        }

        foreach ($matches[0] as $match) {
            $start = $match[1] + strlen($match[0]) - 1;
            $depth = 0;
            $len = strlen($html);

            for ($i = $start; $i < $len; $i++) {
                $char = $html[$i];
                if ($char === '[') {
                    $depth++;
                } elseif ($char === ']') {
                    $depth--;
                    if ($depth === 0) {
                        $json = substr($html, $start, $i - $start + 1);
                        $arr = json_decode($json, true);
                        if (is_array($arr)) {
                            foreach ($arr as $game) {
                                if (is_array($game) && isset($game['equipes'])) {
                                    $out[] = $game;
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
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
     *   external_id: int|null
     * }|null
     */
    private function mapGame(array $game): ?array
    {
        $equipes = $game['equipes'] ?? null;
        if (! is_array($equipes)) {
            return null;
        }

        $home = trim((string) ($equipes['mandante']['nome_popular'] ?? ''));
        $away = trim((string) ($equipes['visitante']['nome_popular'] ?? ''));
        if ($home === '' || $away === '') {
            return null;
        }

        $kickoffRaw = (string) ($game['data_realizacao'] ?? '');
        if ($kickoffRaw === '') {
            return null;
        }

        try {
            // data_realizacao do GE vem sem offset; trata como horário dos EUA (sede da Copa).
            $kickoff = Carbon::parse($kickoffRaw, 'America/New_York')->utc();
        } catch (\Throwable) {
            return null;
        }

        $homeScore = $game['placar_oficial_mandante'] ?? null;
        $awayScore = $game['placar_oficial_visitante'] ?? null;

        return [
            'home_name' => $home,
            'away_name' => $away,
            'kickoff_at' => $kickoff,
            'home_score' => $homeScore !== null ? (int) $homeScore : null,
            'away_score' => $awayScore !== null ? (int) $awayScore : null,
            'started' => (bool) ($game['jogo_ja_comecou'] ?? false),
            'external_id' => isset($game['id']) ? (int) $game['id'] : null,
        ];
    }
}
