<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkTimeline extends Model
{
    protected $table = 'work_timeline';
    protected $primaryKey = 'timeline_id';

    const UPDATED_AT = null;

    protected $fillable = [
        'employee_id',
        'shift_id',
        'work_date',
        'clock_in',
        'clock_out',
        'break_duration_minutes',
        'status',
        'notes',
    ];

    protected $casts = [
        'work_date' => 'date',
        'clock_in' => 'datetime',
        'clock_out' => 'datetime',
        'break_duration_minutes' => 'integer',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    public function shift()
    {
        return $this->belongsTo(WorkShift::class, 'shift_id', 'shift_id');
    }
}
