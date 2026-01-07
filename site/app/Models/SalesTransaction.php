<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SalesTransaction extends Model
{
    protected $table = 'sales_transactions';
    protected $primaryKey = 'transaction_id';

    const UPDATED_AT = null;

    protected $fillable = [
        'partner_id',
        'material_id',
        'quantity_kg',
        'price_per_kg',
        'transaction_date',
        'payment_status',
        'payment_date',
        'invoice_number',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'quantity_kg' => 'decimal:2',
        'price_per_kg' => 'decimal:2',
        'transaction_date' => 'date',
        'payment_date' => 'date',
    ];

    public function partner()
    {
        return $this->belongsTo(Partner::class, 'partner_id', 'partner_id');
    }

    public function materialType()
    {
        return $this->belongsTo(MaterialType::class, 'material_id', 'material_id');
    }

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by', 'user_id');
    }
}
