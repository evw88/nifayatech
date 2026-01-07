<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkShift extends Model
{
    protected $table = 'work_shifts';
    protected $primaryKey = 'shift_id';

    public $timestamps = false;

    protected $fillable = [
        'shift_name',
        'start_time',
        'end_time',
        'description',
    ];

    public function timelines()
    {
        return $this->hasMany(WorkTimeline::class, 'shift_id', 'shift_id');
    }
}
