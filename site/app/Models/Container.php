<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Container extends Model
{
    protected $table = 'containers';
    protected $primaryKey = 'container_id';
    
    protected $fillable = [
        'container_code',
        'type_id',
        'capacity_liters',
        'current_fill_percentage',
        'latitude',
        'longitude',
        'address',
        'zone_id',
        'neighborhood',
        'accessibility_notes',
        'status',
        'alert_threshold',
        'installation_date',
        'last_emptied_at',
        'last_maintenance_date',
        'next_scheduled_collection',
        'sensor_id',
        'last_sensor_update'
    ];

    protected $casts = [
        'current_fill_percentage' => 'decimal:2',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'alert_threshold' => 'decimal:2',
        'installation_date' => 'date',
        'last_emptied_at' => 'datetime',
        'last_maintenance_date' => 'date',
        'next_scheduled_collection' => 'datetime',
        'last_sensor_update' => 'datetime'
    ];

    // Relationships
    public function sensorReadings()
    {
        return $this->hasMany(SensorReading::class, 'container_id', 'container_id');
    }

    public function alerts()
    {
        return $this->hasMany(Alert::class, 'container_id', 'container_id');
    }

    public function zone()
    {
        return $this->belongsTo(Zone::class, 'zone_id', 'zone_id');
    }

    public function containerType()
    {
        return $this->belongsTo(ContainerType::class, 'type_id', 'type_id');
    }

    // Helper method to get fill status
    public function getFillStatusAttribute()
    {
        if ($this->current_fill_percentage >= $this->alert_threshold) {
            return 'urgent';
        } elseif ($this->current_fill_percentage >= 60) {
            return 'soon';
        }
        return 'normal';
    }
}
