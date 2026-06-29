<?php

namespace App\Models;

use App\Services\PredictionWindow;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FootballMatch extends Model
{
    protected $table = 'matches';

    protected $fillable = [
        'home_team_id',
        'away_team_id',
        'kickoff_at',
        'stage',
        'knockout_round',
        'is_opening',
        'home_is_favorite',
        'group_name',
        'venue',
        'status',
        'home_score',
        'away_score',
        'external_id',
        'teams_locked',
        'teams_defined_at',
        'score_locked',
    ];

    protected function casts(): array
    {
        return [
            'kickoff_at' => 'datetime',
            'is_opening' => 'boolean',
            'home_is_favorite' => 'boolean',
            'teams_locked' => 'boolean',
            'teams_defined_at' => 'datetime',
            'external_id' => 'integer',
            'score_locked' => 'boolean',
        ];
    }

    public function homeTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'home_team_id');
    }

    public function awayTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'away_team_id');
    }

    public function predictions(): HasMany
    {
        return $this->hasMany(Prediction::class, 'match_id');
    }

    public function isOpenForPredictions(): bool
    {
        return app(PredictionWindow::class)->isOpenForNewPredictions($this);
    }
}
