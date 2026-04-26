<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        "id",
        "name",
        "phone_number",
        "address",
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
