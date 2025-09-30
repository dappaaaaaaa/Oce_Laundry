<?php

use App\Http\Controllers\OrderExportController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\OrderExportExcelController;
/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/


Route::get('/export/orders', [OrderExportController::class, 'export'])->name('export.orders');


Route::get('/export/orders/excel', [OrderExportExcelController::class, 'export'])->name('orders.export.excel');

Route::get('/', function () {
    return redirect('/admin/login');
});
