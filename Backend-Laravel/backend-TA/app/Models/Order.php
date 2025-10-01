<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
            "total_payment",
            "sub_total",
            "tax",
            "discount",
            "total",
            "total_item",
            "payment_method",
            "transaction_time",
            "customer_name",
            "phone_number",
            "cashier_name",
    ];

    public function items()
{
    return $this->hasMany(OrderItem::class, 'order_id');
}


}
