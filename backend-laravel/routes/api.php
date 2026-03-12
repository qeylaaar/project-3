<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\PineappleController;

Route::get('/pineapple/latest', [PineappleController::class, 'getLatest']);
Route::get('/pineapple/history', [PineappleController::class, 'getHistory']);
Route::get('/nanas/status', [PineappleController::class, 'setStatus']);
