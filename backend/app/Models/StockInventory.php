<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockInventory extends Model
{
    use HasFactory;

    protected $table = 'stock_inventories';
    protected $primaryKey = 'id'; // Sudah default, tapi boleh ditulis


    protected $fillable = [
        'nama',
        'kuantitas',
        'unit',
        'keterangan',
        'image',
    ];
}
