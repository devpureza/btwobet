<?php

namespace App\Services;

use App\Models\Setting;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class BolaoSettings
{
    public const KEY_GROUP_DEADLINE = 'predictions.group_deadline';

    public const KEY_KNOCKOUT_HOURS = 'predictions.knockout_hours_before';

    public const KEY_LOCK_ALL = 'predictions.lock_all';

    private const CACHE_KEY = 'bolao.settings.all';

    public function all(): array
    {
        return Cache::remember(self::CACHE_KEY, 60, function () {
            $rows = Setting::query()->pluck('value', 'key');

            return [
                'group_deadline' => $rows[self::KEY_GROUP_DEADLINE] ?? $this->defaultGroupDeadlineIso(),
                'knockout_hours_before' => (int) ($rows[self::KEY_KNOCKOUT_HOURS] ?? 24),
                'lock_all' => filter_var($rows[self::KEY_LOCK_ALL] ?? false, FILTER_VALIDATE_BOOL),
            ];
        });
    }

    public function groupDeadline(): Carbon
    {
        return Carbon::parse($this->all()['group_deadline']);
    }

    public function knockoutHoursBefore(): int
    {
        return max(0, (int) $this->all()['knockout_hours_before']);
    }

    public function lockAll(): bool
    {
        return (bool) $this->all()['lock_all'];
    }

    public function update(array $data): array
    {
        if (array_key_exists('group_deadline', $data)) {
            Setting::updateOrCreate(
                ['key' => self::KEY_GROUP_DEADLINE],
                ['value' => Carbon::parse($data['group_deadline'])->toIso8601String()],
            );
        }

        if (array_key_exists('knockout_hours_before', $data)) {
            Setting::updateOrCreate(
                ['key' => self::KEY_KNOCKOUT_HOURS],
                ['value' => (string) max(0, (int) $data['knockout_hours_before'])],
            );
        }

        if (array_key_exists('lock_all', $data)) {
            Setting::updateOrCreate(
                ['key' => self::KEY_LOCK_ALL],
                ['value' => $data['lock_all'] ? '1' : '0'],
            );
        }

        Cache::forget(self::CACHE_KEY);

        return $this->all();
    }

    public function seedDefaultsIfMissing(): void
    {
        if (! Setting::query()->where('key', self::KEY_GROUP_DEADLINE)->exists()) {
            Setting::create([
                'key' => self::KEY_GROUP_DEADLINE,
                'value' => $this->defaultGroupDeadlineIso(),
            ]);
        }

        if (! Setting::query()->where('key', self::KEY_KNOCKOUT_HOURS)->exists()) {
            Setting::create([
                'key' => self::KEY_KNOCKOUT_HOURS,
                'value' => '24',
            ]);
        }

        if (! Setting::query()->where('key', self::KEY_LOCK_ALL)->exists()) {
            Setting::create([
                'key' => self::KEY_LOCK_ALL,
                'value' => '0',
            ]);
        }

        Cache::forget(self::CACHE_KEY);
    }

    private function defaultGroupDeadlineIso(): string
    {
        return Carbon::create(2026, 6, 11, 23, 59, 59, 'America/Sao_Paulo')->toIso8601String();
    }
}
