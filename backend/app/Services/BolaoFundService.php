<?php

namespace App\Services;

use App\Models\User;

class BolaoFundService
{
    public function stats(): array
    {
        $perUser = max(0, (int) config('bolao.entry_fee_brl', 50));
        $count = User::query()
            ->where('approval_status', User::STATUS_APPROVED)
            ->count();

        return [
            'participant_count' => $count,
            'amount_per_participant_brl' => $perUser,
            'total_amount_brl' => $count * $perUser,
        ];
    }
}
