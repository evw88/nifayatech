<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VehicleMaintenance extends Model
{
    protected $table = 'vehicle_maintenance';
    protected $primaryKey = 'maintenance_id';

    const UPDATED_AT = null;

    protected $fillable = [
        'vehicle_id',
        'maintenance_date',
        'maintenance_type',
        'description',
        'cost',
        'technician_name',
        'next_service_date',
        'notes',
    ];

    protected $casts = [
        'maintenance_date' => 'date',
        'next_service_date' => 'date',
        'cost' => 'decimal:2',
    ];

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class, 'vehicle_id', 'vehicle_id');
    }
}
