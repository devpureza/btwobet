<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class ScoreSyncStatusService
{
    public const CACHE_KEY = 'worldcup_scores_sync.last_run';

    public function recordRun(array $stats): void
    {
        Cache::put(self::CACHE_KEY, [
            'at' => now()->toIso8601String(),
            'updated' => (int) ($stats['updated'] ?? 0),
        ], now()->addDays(30));
    }

    /**
     * @return array{
     *   source: string,
     *   interval_minutes: int,
     *   last_sync_at: string|null,
     *   next_sync_at: string,
     *   last_updated_matches: int|null
     * }
     */
    public function toArray(): array
    {
        $interval = max(1, (int) config('services.globo_esporte.sync_interval_minutes', 30));
        $source = (string) config('services.globo_esporte.source_label', 'ge.globo');

        $payload = Cache::get(self::CACHE_KEY);
        $lastAt = isset($payload['at']) ? Carbon::parse($payload['at']) : null;

        if ($lastAt) {
            $nextAt = $lastAt->copy()->addMinutes($interval);
            if ($nextAt->isPast()) {
                $nextAt = $this->nextScheduledSlot(now());
            }
        } else {
            $nextAt = $this->nextScheduledSlot(now());
        }

        return [
            'source' => $source,
            'interval_minutes' => $interval,
            'last_sync_at' => $lastAt?->toIso8601String(),
            'next_sync_at' => $nextAt->toIso8601String(),
            'last_updated_matches' => isset($payload['updated']) ? (int) $payload['updated'] : null,
        ];
    }

    private function nextScheduledSlot(Carbon $from): Carbon
    {
        $base = $from->copy()->startOfMinute();
        $minute = (int) $base->format('i');

        if ($minute < 30) {
            return $base->startOfHour()->addMinutes(30);
        }

        return $base->startOfHour()->addHour();
    }
}
