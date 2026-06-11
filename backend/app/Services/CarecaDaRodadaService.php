<?php

namespace App\Services;

use App\Models\User;
use Carbon\Carbon;

class CarecaDaRodadaService
{
    /**
     * Índice do participante da semana (0 = primeiro e-mail em config).
     */
    public function rotationIndexForIsoWeek(int $isoWeek): int
    {
        $emails = $this->candidateEmails();
        $count = count($emails);

        if ($count === 0) {
            return 0;
        }

        return (($isoWeek % $count) + $count) % $count;
    }

    /**
     * @return list<string>
     */
    public function candidateEmails(): array
    {
        $emails = config('bolao.careca_emails', []);

        return array_values(array_filter(
            $emails,
            fn ($email) => is_string($email) && $email !== '',
        ));
    }

    /**
     * @return array<string, mixed>|null
     */
    public function getCarecaOfWeek(?Carbon $at = null): ?array
    {
        $emails = $this->candidateEmails();
        if ($emails === []) {
            return null;
        }

        $moment = ($at ?? Carbon::now('UTC'))->copy();
        $isoWeek = (int) $moment->isoWeek();
        $index = $this->rotationIndexForIsoWeek($isoWeek);
        $email = $emails[$index];
        $user = User::query()->where('email', $email)->first();

        $displayName = $user?->name ?? $this->displayNameFromEmail($email);

        return [
            'key' => 'careca_da_rodada',
            'title' => 'Careca da rodada',
            'subtitle' => 'O destaque capilar da semana',
            'email' => $email,
            'user_id' => $user?->id,
            'display_name' => $displayName,
            'avatar_url' => $user?->avatar_url,
            'iso_week' => $isoWeek,
            'rotation_index' => $index,
        ];
    }

    public function displayNameFromEmail(string $email): string
    {
        $local = explode('@', $email, 2)[0] ?? $email;
        $parts = preg_split('/[._-]+/', $local) ?: [$local];
        $parts = array_filter($parts, fn ($p) => $p !== '');

        if ($parts === []) {
            return $local;
        }

        return implode(' ', array_map(
            fn (string $part) => mb_convert_case($part, MB_CASE_TITLE, 'UTF-8'),
            $parts,
        ));
    }
}
