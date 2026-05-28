<?php

namespace App\Services;

use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class ScoreSyncStatusService
{
    public const CACHE_KEY = 'worldcup_scores_sync.last_run';

    public const SETTING_KEY_AT = 'score_sync.last_at';

    public const SETTING_KEY_UPDATED = 'score_sync.last_updated_matches';

    public function recordRun(array $stats): void
    {
        $payload = [
            'at' => now()->toIso8601String(),
            'updated' => (int) ($stats['updated'] ?? 0),
        ];

        Cache::put(self::CACHE_KEY, $payload, now()->addDays(30));

        Setting::query()->updateOrCreate(
            ['key' => self::SETTING_KEY_AT],
            ['value' => $payload['at']],
        );
        Setting::query()->updateOrCreate(
            ['key' => self::SETTING_KEY_UPDATED],
            ['value' => (string) $payload['updated']],
        );
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

        $payload = $this->lastRunPayload();
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

    /**
     * @return array{at?: string, updated?: int}
     */
    private function lastRunPayload(): array
    {
        $fromSetting = Setting::query()->find(self::SETTING_KEY_AT)?->value;
        if ($fromSetting) {
            $updatedRaw = Setting::query()->find(self::SETTING_KEY_UPDATED)?->value;

            return [
                'at' => $fromSetting,
                'updated' => $updatedRaw !== null ? (int) $updatedRaw : 0,
            ];
        }

        $cached = Cache::get(self::CACHE_KEY);

        return is_array($cached) ? $cached : [];
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
