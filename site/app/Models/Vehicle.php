<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    protected $table = 'vehicles';
    protected $primaryKey = 'vehicle_id';
    
    protected $fillable = [
        'vehicle_code',
        'license_plate',
        'vehicle_type',
        'brand',
        'model',
        'year',
        'capacity_kg',
        'fuel_type',
        'current_latitude',
        'current_longitude',
        'operational_status',
        'last_maintenance_date',
        'next_maintenance_date',
        'odometer_km',
        'purchase_date',
        'insurance_expiry'
    ];

    protected $casts = [
        'year' => 'integer',
        'capacity_kg' => 'integer',
        'current_latitude' => 'decimal:8',
        'current_longitude' => 'decimal:8',
        'last_maintenance_date' => 'date',
        'next_maintenance_date' => 'date',
        'odometer_km' => 'integer',
        'purchase_date' => 'date',
        'insurance_expiry' => 'date'
    ];

    // Relationships
    public function maintenance()
    {
        return $this->hasMany(VehicleMaintenance::class, 'vehicle_id', 'vehicle_id');
    }

    public function assignments()
    {
        return $this->hasMany(VehicleAssignment::class, 'vehicle_id', 'vehicle_id');
    }

    public function alerts()
    {
        return $this->hasMany(Alert::class, 'vehicle_id', 'vehicle_id');
    }
}
