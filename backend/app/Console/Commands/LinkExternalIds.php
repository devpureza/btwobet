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
