<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VehicleAssignment extends Model
{
    protected $table = 'vehicle_assignments';
    protected $primaryKey = 'assignment_id';

    const UPDATED_AT = null;

    protected $fillable = [
        'vehicle_id',
        'employee_id',
        'assignment_date',
        'start_time',
        'end_time',
        'start_odometer',
        'end_odometer',
        'fuel_consumed_liters',
        'status',
        'notes',
    ];

    protected $casts = [
        'assignment_date' => 'date',
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'start_odometer' => 'integer',
        'end_odometer' => 'integer',
        'fuel_consumed_liters' => 'decimal:2',
    ];

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class, 'vehicle_id', 'vehicle_id');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }
}
