<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    protected $table = 'zones';
    protected $primaryKey = 'zone_id';

    const UPDATED_AT = null;
    
    protected $fillable = [
        'zone_name',
        'zone_code',
        'city',
        'district',
        'population',
        'area_km2',
        'description'
    ];

    protected $casts = [
        'population' => 'integer',
        'area_km2' => 'decimal:2'
    ];

    // Relationships
    public function containers()
    {
        return $this->hasMany(Container::class, 'zone_id', 'zone_id');
    }

    public function routes()
    {
        return $this->hasMany(Route::class, 'zone_id', 'zone_id');
    }
}
