<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaterialInventory extends Model
{
    protected $table = 'material_inventory';
    protected $primaryKey = 'inventory_id';

    public $timestamps = false;

    protected $fillable = [
        'material_id',
        'quantity_kg',
        'location',
        'notes',
        'last_updated',
    ];

    protected $casts = [
        'quantity_kg' => 'decimal:2',
        'last_updated' => 'datetime',
    ];

    public function materialType()
    {
        return $this->belongsTo(MaterialType::class, 'material_id', 'material_id');
    }
}
