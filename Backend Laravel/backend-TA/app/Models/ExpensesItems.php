<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExpensesItems extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'expense_id',
        'item_name',
        'qty',
        'price',
        'total'
    ];



    public function expense()
    {
        return $this->belongsTo(Expenses::class, 'expense_id');
    }
}
