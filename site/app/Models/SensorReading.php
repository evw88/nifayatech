<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SensorReading extends Model
{
    protected $table = 'sensor_readings';
    protected $primaryKey = 'reading_id';
    
    public $timestamps = false; // This table doesn't use created_at/updated_at

    protected $fillable = [
        'container_id',
        'fill_percentage',
        'temperature',
        'humidity',
        'battery_level',
        'signal_strength',
        'reading_timestamp'
    ];

    protected $casts = [
        'fill_percentage' => 'decimal:2',
        'temperature' => 'decimal:2',
        'humidity' => 'decimal:2',
        'battery_level' => 'decimal:2',
        'signal_strength' => 'integer',
        'reading_timestamp' => 'datetime'
    ];

    // Relationship
    public function container()
    {
        return $this->belongsTo(Container::class, 'container_id', 'container_id');
    }
}
