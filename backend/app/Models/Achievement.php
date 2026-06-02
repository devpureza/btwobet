<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Achievement extends Model
{
    protected $fillable = [
        'slug',
        'name',
        'description',
        'tier',
        'rule_type',
        'rule_metadata',
        'sort_order',
        'is_trackable',
    ];

    protected function casts(): array
    {
        return [
            'rule_metadata' => 'array',
            'is_trackable' => 'boolean',
        ];
    }

    public function userAchievements(): HasMany
    {
        return $this->hasMany(UserAchievement::class);
    }
}
