<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Route extends Model
{
    protected $table = 'routes';
    protected $primaryKey = 'route_id';

    const UPDATED_AT = null;

    protected $fillable = [
        'route_name',
        'route_code',
        'zone_id',
        'estimated_duration_minutes',
        'total_distance_km',
        'priority_level',
        'status',
        'description',
    ];

    protected $casts = [
        'zone_id' => 'integer',
        'estimated_duration_minutes' => 'integer',
        'total_distance_km' => 'decimal:2',
    ];

    public function zone()
    {
        return $this->belongsTo(Zone::class, 'zone_id', 'zone_id');
    }
}
