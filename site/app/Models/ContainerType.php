<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContainerType extends Model
{
    protected $table = 'container_types';
    protected $primaryKey = 'type_id';
    
    public $timestamps = false;

    protected $fillable = [
        'type_name',
        'color_code',
        'description'
    ];

    // Relationship
    public function containers()
    {
        return $this->hasMany(Container::class, 'type_id', 'type_id');
    }
}
