<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DriverApiController extends Controller
{
    public function dashboard(Request $request)
    {
        $driverId = (int) $request->query('driver_id', 0);

        if ($driverId <= 0) {
            $driverId = (int) DB::table('employees as e')
                ->join('employee_types as et', 'e.employee_type_id', '=', 'et.type_id')
                ->where('et.type_name', '=', 'driver')
                ->orderBy('e.employee_id')
                ->value('e.employee_id');
        }

        if ($driverId <= 0) {
            return response()->json(['error' => 'No driver found'], 404);
        }

        $driver = DB::table('employees as e')
            ->join('users as u', 'e.user_id', '=', 'u.user_id')
            ->join('roles as r', 'u.role_id', '=', 'r.role_id')
            ->join('employee_types as et', 'e.employee_type_id', '=', 'et.type_id')
            ->select(
                'e.employee_id',
                'e.employee_code',
                'e.status as employee_status',
                'et.type_name as employee_type',
                'u.user_id',
                'u.username',
                'u.full_name',
                'u.email',
                'u.phone',
                'u.status as user_status',
                'r.role_id',
                'r.role_name',
                'r.description as role_description'
            )
            ->where('e.employee_id', '=', $driverId)
            ->first();

        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }

        $schedule = $this->fetchSchedule($driverId, true);

        if (!$schedule) {
            $schedule = $this->fetchSchedule($driverId, false);
        }

        if (!$schedule) {
            return response()->json(['error' => 'No schedule found for this driver'], 404);
        }

        $zones = DB::table('zones')
            ->select('zone_id', 'zone_name', 'zone_code', 'city', 'district')
            ->orderBy('zone_name')
            ->get();

        $containerTypes = DB::table('container_types')
            ->select('type_id', 'type_name', 'color_code', 'description')
            ->orderBy('type_name')
            ->get();

        $containers = DB::table('route_containers as rc')
            ->join('containers as c', 'rc.container_id', '=', 'c.container_id')
            ->join('container_types as ct', 'c.type_id', '=', 'ct.type_id')
            ->select(
                'c.container_id',
                'c.container_code',
                'c.type_id',
                'ct.type_name',
                'ct.color_code',
                'c.capacity_liters',
                'c.current_fill_percentage',
                'c.latitude',
                'c.longitude',
                'c.address',
                'c.zone_id',
                'c.status',
                'c.alert_threshold'
            )
            ->where('rc.route_id', '=', $schedule->route_id)
            ->orderBy('rc.sequence_order')
            ->get();

        $alerts = DB::table('alerts')
            ->select('alert_id', 'alert_type', 'severity', 'title', 'message', 'is_read', 'created_at')
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        $shifts = DB::table('work_shifts')
            ->select('shift_id', 'shift_name', 'start_time', 'end_time', 'description')
            ->orderBy('shift_id')
            ->get();

        $timeline = DB::table('work_timeline')
            ->select('timeline_id', 'shift_id', 'work_date', 'status', 'notes')
            ->where('employee_id', '=', $driverId)
            ->orderByDesc('work_date')
            ->limit(5)
            ->get();

        return response()->json([
            'user' => [
                'user_id' => (int) $driver->user_id,
                'username' => $driver->username,
                'full_name' => $driver->full_name,
                'email' => $driver->email,
                'phone' => $driver->phone,
                'status' => $driver->user_status,
                'role_id' => (int) $driver->role_id,
                'role_name' => $driver->role_name,
                'role_description' => $driver->role_description,
            ],
            'employee' => [
                'employee_id' => (int) $driver->employee_id,
                'employee_code' => $driver->employee_code,
                'employee_type' => $driver->employee_type,
                'status' => $driver->employee_status,
            ],
            'partner' => [
                'employee_id' => (int) ($schedule->partner_employee_id ?? 0),
                'employee_code' => $schedule->partner_employee_code ?? '',
                'employee_type' => $schedule->partner_employee_type ?? '',
                'status' => $schedule->partner_status ?? '',
                'user_id' => (int) ($schedule->partner_user_id ?? 0),
                'username' => $schedule->partner_username ?? '',
                'full_name' => $schedule->partner_full_name ?? '',
                'email' => $schedule->partner_email ?? '',
                'phone' => $schedule->partner_phone ?? '',
                'role_id' => (int) ($schedule->partner_role_id ?? 0),
                'role_name' => $schedule->partner_role_name ?? '',
                'role_description' => $schedule->partner_role_description ?? '',
            ],
            'vehicle' => [
                'vehicle_id' => (int) ($schedule->vehicle_id ?? 0),
                'vehicle_code' => $schedule->vehicle_code ?? '',
                'license_plate' => $schedule->license_plate ?? '',
                'vehicle_type' => $schedule->vehicle_type ?? '',
                'capacity_kg' => (int) ($schedule->capacity_kg ?? 0),
                'operational_status' => $schedule->operational_status ?? '',
                'current_latitude' => $schedule->current_latitude,
                'current_longitude' => $schedule->current_longitude,
            ],
            'route' => [
                'route_id' => (int) $schedule->route_id,
                'route_name' => $schedule->route_name,
                'route_code' => $schedule->route_code,
                'zone_id' => (int) $schedule->zone_id,
                'estimated_duration_minutes' => (int) $schedule->estimated_duration_minutes,
                'total_distance_km' => (float) $schedule->total_distance_km,
                'priority_level' => $schedule->priority_level,
                'status' => $schedule->route_status,
            ],
            'schedule' => [
                'schedule_id' => (int) $schedule->schedule_id,
                'scheduled_date' => $schedule->scheduled_date,
                'scheduled_start_time' => $schedule->scheduled_start_time,
                'status' => $schedule->status,
            ],
            'zones' => $zones,
            'container_types' => $containerTypes,
            'containers' => $containers,
            'alerts' => $alerts,
            'shifts' => $shifts,
            'timeline' => $timeline,
        ]);
    }

    public function availableDrivers(Request $request)
    {
        $driverId = (int) $request->query('driver_id', 0);
        $scheduleId = (int) $request->query('schedule_id', 0);

        if ($driverId <= 0) {
            return response()->json(['error' => 'driver_id is required'], 400);
        }

        if ($scheduleId > 0) {
            $schedule = DB::table('collection_schedules')
                ->where('schedule_id', '=', $scheduleId)
                ->where('driver_id', '=', $driverId)
                ->first();
        } else {
            $schedule = $this->latestScheduleForDriver($driverId);
        }

        if (!$schedule) {
            return response()->json([]);
        }

        $baseQuery = DB::table('collection_schedules as cs')
            ->join('employees as e', 'cs.driver_id', '=', 'e.employee_id')
            ->join('users as u', 'e.user_id', '=', 'u.user_id')
            ->join('employee_types as et', 'e.employee_type_id', '=', 'et.type_id')
            ->where('et.type_name', '=', 'driver')
            ->where('e.employee_id', '!=', $driverId)
            ->select(
                'e.employee_id',
                'e.employee_code',
                'u.full_name',
                'cs.schedule_id',
                'cs.scheduled_date',
                'cs.scheduled_start_time'
            )
            ->orderByDesc('cs.scheduled_date')
            ->orderByDesc('cs.scheduled_start_time');

        $drivers = (clone $baseQuery)
            ->where('cs.scheduled_date', '=', $schedule->scheduled_date)
            ->get();

        if ($drivers->isEmpty()) {
            $drivers = $baseQuery->get();
        }

        $drivers = collect($drivers)->unique('employee_id')->values();

        return response()->json($drivers);
    }

    public function swapRequests(Request $request)
    {
        $driverId = (int) $request->query('driver_id', 0);

        if ($driverId <= 0) {
            return response()->json(['error' => 'driver_id is required'], 400);
        }

        $requests = DB::table('shift_swap_requests as ssr')
            ->join('employees as er', 'ssr.requester_employee_id', '=', 'er.employee_id')
            ->join('users as ur', 'er.user_id', '=', 'ur.user_id')
            ->join('employees as et', 'ssr.target_employee_id', '=', 'et.employee_id')
            ->join('users as ut', 'et.user_id', '=', 'ut.user_id')
            ->join('collection_schedules as cs', 'ssr.schedule_id', '=', 'cs.schedule_id')
            ->join('collection_schedules as cst', 'ssr.target_schedule_id', '=', 'cst.schedule_id')
            ->select(
                'ssr.request_id',
                'ssr.status',
                'ssr.message',
                'ssr.created_at',
                'ssr.responded_at',
                'er.employee_id as requester_id',
                'er.employee_code as requester_code',
                'ur.full_name as requester_name',
                'et.employee_id as target_id',
                'et.employee_code as target_code',
                'ut.full_name as target_name',
                'cs.schedule_id',
                'cs.scheduled_date',
                'cs.scheduled_start_time',
                'cst.schedule_id as target_schedule_id'
            )
            ->where(function ($query) use ($driverId) {
                $query->where('ssr.requester_employee_id', '=', $driverId)
                    ->orWhere('ssr.target_employee_id', '=', $driverId);
            })
            ->orderByDesc('ssr.created_at')
            ->get();

        return response()->json($requests);
    }

    public function createSwapRequest(Request $request)
    {
        $payload = $request->validate([
            'requester_id' => 'required|integer|min:1',
            'target_id' => 'required|integer|min:1',
            'schedule_id' => 'required|integer|min:1',
            'target_schedule_id' => 'nullable|integer|min:1',
            'message' => 'nullable|string',
        ]);

        $requesterId = (int) $payload['requester_id'];
        $targetId = (int) $payload['target_id'];
        $scheduleId = (int) $payload['schedule_id'];
        $targetScheduleId = (int) ($payload['target_schedule_id'] ?? 0);

        if ($requesterId === $targetId) {
            return response()->json(['error' => 'Cannot swap with the same driver'], 400);
        }

        $schedule = DB::table('collection_schedules')
            ->where('schedule_id', '=', $scheduleId)
            ->where('driver_id', '=', $requesterId)
            ->first();

        if (!$schedule) {
            return response()->json(['error' => 'Schedule not found for requester'], 404);
        }

        if ($targetScheduleId > 0) {
            $targetSchedule = DB::table('collection_schedules')
                ->where('schedule_id', '=', $targetScheduleId)
                ->where('driver_id', '=', $targetId)
                ->first();

            if (!$targetSchedule) {
                return response()->json(['error' => 'Target schedule not found'], 404);
            }
        } else {
            $targetSchedule = DB::table('collection_schedules')
                ->where('driver_id', '=', $targetId)
                ->where('scheduled_date', '=', $schedule->scheduled_date)
                ->orderByDesc('scheduled_start_time')
                ->first();

            if (!$targetSchedule) {
                return response()->json(['error' => 'Target driver has no schedule on this date'], 404);
            }

            $targetScheduleId = (int) $targetSchedule->schedule_id;
        }

        $exists = DB::table('shift_swap_requests')
            ->where('requester_employee_id', '=', $requesterId)
            ->where('target_employee_id', '=', $targetId)
            ->where('schedule_id', '=', $scheduleId)
            ->where('status', '=', 'pending')
            ->exists();

        if ($exists) {
            return response()->json(['error' => 'A pending swap request already exists'], 409);
        }

        $requestId = DB::table('shift_swap_requests')->insertGetId([
            'requester_employee_id' => $requesterId,
            'target_employee_id' => $targetId,
            'schedule_id' => $scheduleId,
            'target_schedule_id' => $targetScheduleId,
            'message' => $payload['message'] ?? null,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'request_id' => (int) $requestId,
            'status' => 'pending',
        ], 201);
    }

    public function respondSwapRequest(Request $request, int $requestId)
    {
        $payload = $request->validate([
            'action' => 'required|string|in:accept,decline,cancel',
        ]);

        $swap = DB::table('shift_swap_requests')
            ->where('request_id', '=', $requestId)
            ->first();

        if (!$swap) {
            return response()->json(['error' => 'Swap request not found'], 404);
        }

        if ($swap->status !== 'pending') {
            return response()->json(['error' => 'Swap request already processed'], 409);
        }

        $action = $payload['action'];

        if ($action === 'accept') {
            DB::transaction(function () use ($swap) {
                $scheduleA = DB::table('collection_schedules')
                    ->where('schedule_id', '=', $swap->schedule_id)
                    ->lockForUpdate()
                    ->first();
                $scheduleB = DB::table('collection_schedules')
                    ->where('schedule_id', '=', $swap->target_schedule_id)
                    ->lockForUpdate()
                    ->first();

                if (!$scheduleA || !$scheduleB) {
                    throw new \RuntimeException('Schedule not found for swap');
                }

                DB::table('collection_schedules')
                    ->where('schedule_id', '=', $swap->schedule_id)
                    ->update([
                        'driver_id' => $swap->target_employee_id,
                    ]);

                DB::table('collection_schedules')
                    ->where('schedule_id', '=', $swap->target_schedule_id)
                    ->update([
                        'driver_id' => $swap->requester_employee_id,
                    ]);

                DB::table('shift_swap_requests')
                    ->where('request_id', '=', $swap->request_id)
                    ->update([
                        'status' => 'accepted',
                        'responded_at' => now(),
                        'updated_at' => now(),
                    ]);
            });
        } elseif ($action === 'decline') {
            DB::table('shift_swap_requests')
                ->where('request_id', '=', $swap->request_id)
                ->update([
                    'status' => 'declined',
                    'responded_at' => now(),
                    'updated_at' => now(),
                ]);
        } elseif ($action === 'cancel') {
            DB::table('shift_swap_requests')
                ->where('request_id', '=', $swap->request_id)
                ->update([
                    'status' => 'cancelled',
                    'responded_at' => now(),
                    'updated_at' => now(),
                ]);
        }

        return response()->json(['status' => $action]);
    }

    public function startShift(Request $request)
    {
        $payload = $request->validate([
            'driver_id' => 'required|integer|min:1',
            'schedule_id' => 'required|integer|min:1',
        ]);

        $updated = DB::table('collection_schedules')
            ->where('schedule_id', '=', $payload['schedule_id'])
            ->where('driver_id', '=', $payload['driver_id'])
            ->where('status', '=', 'scheduled')
            ->update([
                'status' => 'in_progress',
                'actual_start_time' => now(),
            ]);

        if ($updated === 0) {
            return response()->json(['error' => 'Schedule not found or already started'], 404);
        }

        return response()->json(['status' => 'in_progress']);
    }

    public function completeShift(Request $request)
    {
        $payload = $request->validate([
            'driver_id' => 'required|integer|min:1',
            'schedule_id' => 'required|integer|min:1',
        ]);

        $updated = DB::table('collection_schedules')
            ->where('schedule_id', '=', $payload['schedule_id'])
            ->where('driver_id', '=', $payload['driver_id'])
            ->where('status', '=', 'in_progress')
            ->update([
                'status' => 'completed',
                'actual_end_time' => now(),
            ]);

        if ($updated === 0) {
            return response()->json(['error' => 'Schedule not in progress'], 404);
        }

        return response()->json(['status' => 'completed']);
    }

    public function reportIssue(Request $request)
    {
        $payload = $request->validate([
            'title' => 'required|string|max:200',
            'message' => 'required|string',
            'severity' => 'nullable|in:low,medium,high,critical',
            'route_id' => 'nullable|integer',
            'vehicle_id' => 'nullable|integer',
            'container_id' => 'nullable|integer',
            'assigned_to' => 'nullable|integer',
        ]);

        $alertId = DB::table('alerts')->insertGetId([
            'alert_type' => 'system',
            'severity' => $payload['severity'] ?? 'medium',
            'container_id' => $payload['container_id'] ?? null,
            'vehicle_id' => $payload['vehicle_id'] ?? null,
            'route_id' => $payload['route_id'] ?? null,
            'title' => $payload['title'],
            'message' => $payload['message'],
            'assigned_to' => $payload['assigned_to'] ?? null,
            'created_at' => now(),
        ]);

        return response()->json(['alert_id' => (int) $alertId], 201);
    }

    private function fetchSchedule(int $driverId, bool $todayOnly)
    {
        $query = DB::table('collection_schedules as cs')
            ->join('routes as r', 'cs.route_id', '=', 'r.route_id')
            ->leftJoin('vehicles as v', 'cs.vehicle_id', '=', 'v.vehicle_id')
            ->leftJoin('employees as ep', 'cs.partner_id', '=', 'ep.employee_id')
            ->leftJoin('employee_types as etp', 'ep.employee_type_id', '=', 'etp.type_id')
            ->leftJoin('users as up', 'ep.user_id', '=', 'up.user_id')
            ->leftJoin('roles as rr', 'up.role_id', '=', 'rr.role_id')
            ->select(
                'cs.schedule_id',
                'cs.scheduled_date',
                'cs.scheduled_start_time',
                'cs.status',
                'r.route_id',
                'r.route_name',
                'r.route_code',
                'r.zone_id',
                'r.estimated_duration_minutes',
                'r.total_distance_km',
                'r.priority_level',
                'r.status as route_status',
                'v.vehicle_id',
                'v.vehicle_code',
                'v.license_plate',
                'v.vehicle_type',
                'v.capacity_kg',
                'v.operational_status',
                'v.current_latitude',
                'v.current_longitude',
                'ep.employee_id as partner_employee_id',
                'ep.employee_code as partner_employee_code',
                'etp.type_name as partner_employee_type',
                'up.user_id as partner_user_id',
                'up.username as partner_username',
                'up.full_name as partner_full_name',
                'up.email as partner_email',
                'up.phone as partner_phone',
                'up.status as partner_status',
                'rr.role_id as partner_role_id',
                'rr.role_name as partner_role_name',
                'rr.description as partner_role_description'
            )
            ->where('cs.driver_id', '=', $driverId);

        if ($todayOnly) {
            $query->whereDate('cs.scheduled_date', '=', now()->toDateString());
        }

        return $query
            ->orderByDesc('cs.scheduled_date')
            ->orderByDesc('cs.scheduled_start_time')
            ->first();
    }

    private function latestScheduleForDriver(int $driverId)
    {
        return DB::table('collection_schedules')
            ->where('driver_id', '=', $driverId)
            ->orderByDesc('scheduled_date')
            ->orderByDesc('scheduled_start_time')
            ->first();
    }
}
