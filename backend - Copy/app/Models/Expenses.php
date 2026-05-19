<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Expenses extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        "expenses_category_id",
        "date",
        "description",
        "amount",
    ];



    public function category()
    {
        return $this->belongsTo(ExpensesCategory::class, 'expenses_category_id');
    }
    

    public function items()
    {
        return $this->hasMany(ExpensesItems::class, 'expense_id');
    }
}
