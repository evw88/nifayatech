<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    protected $table = 'employees';
    protected $primaryKey = 'employee_id';

    const UPDATED_AT = null;
    
    protected $fillable = [
        'user_id',
        'employee_code',
        'employee_type_id',
        'hire_date',
        'salary',
        'license_number',
        'license_expiry',
        'emergency_contact_name',
        'emergency_contact_phone',
        'status'
    ];

    protected $casts = [
        'hire_date' => 'date',
        'license_expiry' => 'date',
        'salary' => 'decimal:2'
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }

    public function employeeType()
    {
        return $this->belongsTo(EmployeeType::class, 'employee_type_id', 'type_id');
    }

    public function workTimeline()
    {
        return $this->hasMany(WorkTimeline::class, 'employee_id', 'employee_id');
    }

    public function vehicleAssignments()
    {
        return $this->hasMany(VehicleAssignment::class, 'employee_id', 'employee_id');
    }
}
