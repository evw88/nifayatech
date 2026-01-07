<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Partner extends Model
{
    protected $table = 'partners';
    protected $primaryKey = 'partner_id';

    const UPDATED_AT = null;
    
    protected $fillable = [
        'partner_name',
        'contact_person',
        'email',
        'phone',
        'address',
        'partner_type',
        'status',
        'payment_terms',
        'rating',
        'notes'
    ];

    protected $casts = [
        'rating' => 'decimal:2'
    ];

    // Relationships
    public function materials()
    {
        return $this->belongsToMany(MaterialType::class, 'partner_materials', 'partner_id', 'material_id')
                    ->withPivot('current_price_per_kg', 'minimum_quantity_kg', 'last_price_update');
    }

    public function salesTransactions()
    {
        return $this->hasMany(SalesTransaction::class, 'partner_id', 'partner_id');
    }
}
