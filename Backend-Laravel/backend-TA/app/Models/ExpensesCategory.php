<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExpensesCategory extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        "name",
    ];

    public function expenses()
    {
        return $this->hasMany(Expenses::class, 'expenses_category_id');
    }

}
