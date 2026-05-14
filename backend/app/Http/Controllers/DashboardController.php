<?php

namespace App\Http\Controllers;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    //<?php
    public function chartTransaksi(Request $request)
    {
        try {

            $filter = $request->get('filter', 'harian');

            switch ($filter) {

                // =========================
                // HARIAN
                // =========================
                case 'harian':

                    $data = Order::select(
                        DB::raw('HOUR(transaction_time) as label'),
                        DB::raw('COUNT(*) as total')
                    )
                        ->whereDate(
                            'transaction_time',
                            now()->toDateString()
                        )
                        ->groupBy('label')
                        ->orderBy('label')
                        ->get();

                    break;

                // =========================
                // MINGGUAN
                // =========================
                case 'mingguan':

                    $data = Order::select(
                        DB::raw('DATE(transaction_time) as label'),
                        DB::raw('COUNT(*) as total')
                    )
                        ->where(
                            'transaction_time',
                            '>=',
                            now()->subDays(7)
                        )
                        ->groupBy('label')
                        ->orderBy('label')
                        ->get();

                    break;

                // =========================
                // BULANAN
                // =========================
                case 'bulanan':

                    $data = Order::select(
                        DB::raw('DATE(transaction_time) as label'),
                        DB::raw('COUNT(*) as total')
                    )
                        ->whereMonth(
                            'transaction_time',
                            now()->month
                        )
                        ->whereYear(
                            'transaction_time',
                            now()->year
                        )
                        ->groupBy('label')
                        ->orderBy('label')
                        ->get();

                    break;

                default:

                    return response()->json([
                        'status' => false,
                        'message' => 'Filter tidak valid'
                    ], 400);
            }

            return response()->json([
                'status' => true,
                'message' => 'Berhasil mengambil chart transaksi',
                'data' => $data,
            ], 200);

        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}

