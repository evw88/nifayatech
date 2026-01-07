<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaterialType extends Model
{
    protected $table = 'material_types';
    protected $primaryKey = 'material_id';

    const UPDATED_AT = null;
    
    protected $fillable = [
        'material_name',
        'description',
        'unit',
        'recyclable'
    ];

    protected $casts = [
        'recyclable' => 'boolean'
    ];

    // Relationships
    public function partners()
    {
        return $this->belongsToMany(Partner::class, 'partner_materials', 'material_id', 'partner_id')
                    ->withPivot('current_price_per_kg', 'minimum_quantity_kg');
    }

    public function inventory()
    {
        return $this->hasMany(MaterialInventory::class, 'material_id', 'material_id');
    }

    public function salesTransactions()
    {
        return $this->hasMany(SalesTransaction::class, 'material_id', 'material_id');
    }
}
