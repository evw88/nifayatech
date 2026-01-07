<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Alert extends Model
{
    protected $table = 'alerts';
    protected $primaryKey = 'alert_id';
    
    public $timestamps = false;

    protected $fillable = [
        'alert_type',
        'severity',
        'container_id',
        'vehicle_id',
        'route_id',
        'title',
        'message',
        'is_read',
        'is_resolved',
        'assigned_to',
        'resolved_by',
        'resolved_at',
        'created_at'
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'is_resolved' => 'boolean',
        'resolved_at' => 'datetime',
        'created_at' => 'datetime'
    ];

    // Relationships
    public function container()
    {
        return $this->belongsTo(Container::class, 'container_id', 'container_id');
    }

    public function vehicle()
    {
        return $this->belongsTo(Vehicle::class, 'vehicle_id', 'vehicle_id');
    }

    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_to', 'user_id');
    }

    public function resolvedByUser()
    {
        return $this->belongsTo(User::class, 'resolved_by', 'user_id');
    }
}
