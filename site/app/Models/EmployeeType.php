<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmployeeType extends Model
{
    protected $table = 'employee_types';
    protected $primaryKey = 'type_id';

    public $timestamps = false;

    protected $fillable = [
        'type_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'employee_type_id', 'type_id');
    }
}
