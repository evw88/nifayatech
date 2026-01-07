<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SensorController extends Controller
{
    /**
     * Update sensor data for a container
     * GET|POST /api/v1/sensor/update
     */
    public function updateSensor(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'container_code' => 'required|string|exists:containers,container_code',
            'fill_percentage' => 'required|numeric|min:0|max:100',
            'temperature' => 'nullable|numeric|min:-50|max:100',
            'humidity' => 'nullable|numeric|min:0|max:100',
            'battery_level' => 'nullable|numeric|min:0|max:100',
            'signal_strength' => 'nullable|integer|min:-120|max:0',
            'api_token' => 'nullable|string' // Optional security token
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        // Find container
        $container = DB::table('containers')
            ->where('container_code', $request->container_code)
            ->first();

        if (!$container) {
            return response()->json([
                'success' => false,
                'message' => 'Container not found'
            ], 404);
        }

        // Verify API token if provided
        if ($request->filled('api_token') && isset($container->api_token)) {
            if ($request->api_token !== $container->api_token) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid API token'
                ], 401);
            }
        }

        try {
            DB::beginTransaction();

            // Insert sensor reading
            $readingId = DB::table('sensor_readings')->insertGetId([
                'container_id' => $container->container_id,
                'fill_percentage' => $request->fill_percentage,
                'temperature' => $request->temperature,
                'humidity' => $request->humidity,
                'battery_level' => $request->battery_level,
                'signal_strength' => $request->signal_strength,
                'reading_timestamp' => now()
            ]);

            // Update container (trigger will also do this, but manual update ensures consistency)
            DB::table('containers')
                ->where('container_id', $container->container_id)
                ->update([
                    'current_fill_percentage' => $request->fill_percentage,
                    'last_sensor_update' => now(),
                    'updated_at' => now()
                ]);

            // Check if alert threshold reached
            $alertCreated = false;
            if ($request->fill_percentage >= $container->alert_threshold 
                && $container->status === 'active') {
                
                // Check if alert already exists for this container
                $existingAlert = DB::table('alerts')
                    ->where('container_id', $container->container_id)
                    ->where('alert_type', 'container_full')
                    ->where('is_resolved', false)
                    ->exists();

                if (!$existingAlert) {
                    DB::table('alerts')->insert([
                        'alert_type' => 'container_full',
                        'severity' => 'high',
                        'container_id' => $container->container_id,
                        'title' => "Container {$container->container_code} requires collection",
                        'message' => "Container at {$container->address} has reached {$request->fill_percentage}% capacity",
                        'created_at' => now()
                    ]);
                    $alertCreated = true;
                }
            }

            // Check battery level alert
            if ($request->filled('battery_level') && $request->battery_level < 20) {
                $existingBatteryAlert = DB::table('alerts')
                    ->where('container_id', $container->container_id)
                    ->where('alert_type', 'low_battery')
                    ->where('is_resolved', false)
                    ->exists();

                if (!$existingBatteryAlert) {
                    DB::table('alerts')->insert([
                        'alert_type' => 'low_battery',
                        'severity' => 'medium',
                        'container_id' => $container->container_id,
                        'title' => "Low battery on container {$container->container_code}",
                        'message' => "Sensor battery level is at {$request->battery_level}%",
                        'created_at' => now()
                    ]);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Sensor data updated successfully',
                'data' => [
                    'reading_id' => $readingId,
                    'container_code' => $container->container_code,
                    'fill_percentage' => $request->fill_percentage,
                    'alert_created' => $alertCreated,
                    'timestamp' => now()->toISOString()
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            
            return response()->json([
                'success' => false,
                'message' => 'Error updating sensor data',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Add reading by sensor ID
     * POST /api/v1/sensor/{sensor_id}/reading
     */
    public function addReading(Request $request, $sensor_id)
    {
        $validator = Validator::make($request->all(), [
            'fill_percentage' => 'required|numeric|min:0|max:100',
            'temperature' => 'nullable|numeric|min:-50|max:100',
            'humidity' => 'nullable|numeric|min:0|max:100',
            'battery_level' => 'nullable|numeric|min:0|max:100',
            'signal_strength' => 'nullable|integer|min:-120|max:0'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $container = DB::table('containers')
            ->where('sensor_id', $sensor_id)
            ->first();

        if (!$container) {
            return response()->json([
                'success' => false,
                'message' => 'Sensor not found'
            ], 404);
        }

        // Reuse the update logic
        $request->merge(['container_code' => $container->container_code]);
        return $this->updateSensor($request);
    }

    /**
     * Bulk update multiple sensors
     * POST /api/v1/sensor/bulk-update
     */
    public function bulkUpdate(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'sensors' => 'required|array|min:1',
            'sensors.*.container_code' => 'required|string',
            'sensors.*.fill_percentage' => 'required|numeric|min:0|max:100',
            'sensors.*.temperature' => 'nullable|numeric|min:-50|max:100',
            'sensors.*.humidity' => 'nullable|numeric|min:0|max:100',
            'sensors.*.battery_level' => 'nullable|numeric|min:0|max:100',
            'sensors.*.signal_strength' => 'nullable|integer|min:-120|max:0'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $results = [];
        $successCount = 0;
        $failureCount = 0;

        foreach ($request->sensors as $sensorData) {
            try {
                $tempRequest = new Request($sensorData);
                $response = $this->updateSensor($tempRequest);
                
                if ($response->getStatusCode() === 200) {
                    $successCount++;
                    $results[] = [
                        'container_code' => $sensorData['container_code'],
                        'status' => 'success'
                    ];
                } else {
                    $failureCount++;
                    $results[] = [
                        'container_code' => $sensorData['container_code'],
                        'status' => 'failed',
                        'message' => $response->getData()->message ?? 'Unknown error'
                    ];
                }
            } catch (\Exception $e) {
                $failureCount++;
                $results[] = [
                    'container_code' => $sensorData['container_code'],
                    'status' => 'failed',
                    'message' => $e->getMessage()
                ];
            }
        }

        return response()->json([
            'success' => true,
            'message' => "Processed {$successCount} successful, {$failureCount} failed",
            'summary' => [
                'total' => count($request->sensors),
                'successful' => $successCount,
                'failed' => $failureCount
            ],
            'results' => $results
        ], 200);
    }

    /**
     * Get container status
     * GET /api/v1/container/{container_code}/status
     */
    public function getStatus($container_code)
    {
        $container = DB::table('containers')
            ->join('container_types', 'containers.type_id', '=', 'container_types.type_id')
            ->leftJoin('zones', 'containers.zone_id', '=', 'zones.zone_id')
            ->where('containers.container_code', $container_code)
            ->select(
                'containers.*',
                'container_types.type_name',
                'container_types.color_code',
                'zones.zone_name'
            )
            ->first();

        if (!$container) {
            return response()->json([
                'success' => false,
                'message' => 'Container not found'
            ], 404);
        }

        // Get latest sensor reading
        $latestReading = DB::table('sensor_readings')
            ->where('container_id', $container->container_id)
            ->orderBy('reading_timestamp', 'desc')
            ->first();

        // Calculate priority
        $priority = 'normal';
        if ($container->current_fill_percentage >= $container->alert_threshold) {
            $priority = 'urgent';
        } elseif ($container->current_fill_percentage >= 60) {
            $priority = 'soon';
        }

        return response()->json([
            'success' => true,
            'data' => [
                'container_code' => $container->container_code,
                'type' => $container->type_name,
                'capacity_liters' => $container->capacity_liters,
                'current_fill_percentage' => (float) $container->current_fill_percentage,
                'current_fill_liters' => (float) $container->current_fill_liters,
                'status' => $container->status,
                'priority' => $priority,
                'location' => [
                    'latitude' => (float) $container->latitude,
                    'longitude' => (float) $container->longitude,
                    'address' => $container->address,
                    'zone' => $container->zone_name
                ],
                'last_update' => $container->last_sensor_update,
                'latest_reading' => $latestReading ? [
                    'temperature' => $latestReading->temperature,
                    'humidity' => $latestReading->humidity,
                    'battery_level' => $latestReading->battery_level,
                    'signal_strength' => $latestReading->signal_strength,
                    'timestamp' => $latestReading->reading_timestamp
                ] : null
            ]
        ], 200);
    }
}
