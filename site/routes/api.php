<?php

use App\Http\Controllers\DriverApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SensorController;
/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/driver/dashboard', [DriverApiController::class, 'dashboard']);
Route::get('/driver/available-drivers', [DriverApiController::class, 'availableDrivers']);
Route::get('/driver/swap-requests', [DriverApiController::class, 'swapRequests']);
Route::post('/driver/swap-requests', [DriverApiController::class, 'createSwapRequest']);
Route::post('/driver/swap-requests/{requestId}/respond', [DriverApiController::class, 'respondSwapRequest']);
Route::post('/driver/shift/start', [DriverApiController::class, 'startShift']);
Route::post('/driver/shift/complete', [DriverApiController::class, 'completeShift']);
Route::post('/driver/report-issue', [DriverApiController::class, 'reportIssue']);
// routes/api.php


Route::prefix('v1')->group(function () {
    // Update sensor data by container code
    Route::match(['get', 'post'], '/sensor/update', [SensorController::class, 'updateSensor']);
    
    // Update sensor data by sensor ID
    Route::post('/sensor/{sensor_id}/reading', [SensorController::class, 'addReading']);
    
    // Bulk update multiple sensors
    Route::post('/sensor/bulk-update', [SensorController::class, 'bulkUpdate']);
    
    // Get container status
    Route::get('/container/{container_code}/status', [SensorController::class, 'getStatus']);
});
