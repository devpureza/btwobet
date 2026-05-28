<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BolaoFundController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\HistoryController;
use App\Http\Controllers\Api\MatchController;
use App\Http\Controllers\Api\PredictionController;
use App\Http\Controllers\Api\RankingController;
use App\Http\Controllers\Api\ScoreSyncController;
use App\Http\Controllers\Api\Admin\BolaoResetAdminController;
use App\Http\Controllers\Api\Admin\PredictionHistoryAdminController;
use App\Http\Controllers\Api\Admin\PredictionRulesAdminController;
use App\Http\Controllers\Api\Admin\UserAdminController;
use App\Http\Controllers\Api\Admin\MatchAdminController;
use App\Http\Controllers\Api\Admin\TeamAdminController;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class);
Route::get('/score-sync/status', ScoreSyncController::class);

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::patch('/me', [AuthController::class, 'updateMe']);
    Route::post('/me/avatar', [AuthController::class, 'uploadAvatar']);

    Route::middleware('approved')->group(function () {
        Route::get('/bolao/fund', BolaoFundController::class);
        Route::get('/matches', [MatchController::class, 'index']);
        Route::post('/predictions', [PredictionController::class, 'store']);
        Route::get('/ranking', [RankingController::class, 'index']);
        Route::get('/me/history', HistoryController::class);

        Route::middleware('admin')->prefix('admin')->group(function () {
            Route::get('/users', [UserAdminController::class, 'index']);
            Route::post('/users', [UserAdminController::class, 'store']);
            Route::patch('/users/{user}', [UserAdminController::class, 'update']);
            Route::post('/users/{user}/approve', [UserAdminController::class, 'approve']);
            Route::post('/users/{user}/reject', [UserAdminController::class, 'reject']);
            Route::delete('/users/{user}', [UserAdminController::class, 'destroy']);

            Route::get('/matches', [MatchAdminController::class, 'index']);
            Route::patch('/matches/{match}/result', [MatchAdminController::class, 'updateResult']);
            Route::patch('/matches/{match}', [MatchAdminController::class, 'update']);

            Route::get('/teams', [TeamAdminController::class, 'index']);
            Route::patch('/teams/{team}', [TeamAdminController::class, 'update']);
            Route::post('/teams/{team}/flag', [TeamAdminController::class, 'uploadFlag']);

            Route::get('/prediction-rules', [PredictionRulesAdminController::class, 'show']);
            Route::patch('/prediction-rules', [PredictionRulesAdminController::class, 'update']);

            Route::get('/predictions', [PredictionHistoryAdminController::class, 'index']);

            Route::post('/reset', BolaoResetAdminController::class);
        });
    });
});
