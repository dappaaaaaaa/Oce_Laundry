<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use App\Models\orders;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class OrdersController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        try {

            $orders = Order::where(function ($query) {

                $query->where('is_order_complete', '!=', 3)

                    ->orWhere('is_payment_complete', 0)

                    ->orWhere(function ($q) {

                        $q->where('is_order_complete', 3)
                            ->where('is_payment_complete', 1)
                            ->where(
                                'updated_at',
                                '>=',
                                Carbon::now()->subHours(24)
                            );
                    });
            })
                ->orderBy('id', 'desc')
                ->get()
                ->map(function ($order) {

                    $order->phone_number = $order->phone_number ?? '';

                    return $order;
                });

            return response()->json([
                'status' => true,
                'message' => 'Berhasil mengambil data order',
                'data' => $orders,
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Store a newly created resource in storage.
     */

    public function store(Request $request)
    {
        $dataOrders = new Order;

        $rules = [
            'total_payment' => 'required|integer',
            'sub_total' => 'required|integer',
            'tax' => 'required|integer',
            'discount' => 'required|integer',
            'total' => 'required|integer',
            'payment_method' => 'required',
            'transaction_time' => 'required|date_format:Y-m-d H:i:s',
            'transaction_complete_time' => 'nullable|date_format:Y-m-d H:i:s',
            'customer_name' => 'required|string',
            'cashier_name' => 'required|string',
            'phone_number' => 'nullable|string|min:10|max:14',
            'is_order_complete' => 'required|boolean',
            'is_payment_complete' => 'required|boolean',
        ];

        $validator = Validator::make($request->all(), $rules);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal Memasukan Data',
                'data' => $validator->errors(),
            ], 400);
        }

        try {
            $dataOrders->total_payment = $request->total_payment;
            $dataOrders->sub_total = $request->sub_total;
            $dataOrders->tax = $request->tax;
            $dataOrders->discount = $request->discount;
            $dataOrders->total = $request->total;
            $dataOrders->total_item = $request->total_item;
            $dataOrders->phone_number = $request->phone_number;
            $dataOrders->payment_method = $request->payment_method;
            $dataOrders->transaction_time = $request->transaction_time;
            $dataOrders->transaction_complete_time = $request->transaction_complete_time;
            $dataOrders->customer_name = $request->customer_name;
            $dataOrders->cashier_name = $request->cashier_name;
            $dataOrders->is_order_complete = $request->is_order_complete;
            $dataOrders->is_payment_complete = $request->is_payment_complete;

            $dataOrders->save();

            return response()->json([
                'status' => true,
                'message' => 'Sukses Memasukan Data',
                'id' => $dataOrders->id,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Gagal menyimpan data: ' . $e->getMessage(),
            ], 500);
        }
    }


    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        try {

            $order = Order::find($id);

            if (!$order) {

                return response()->json([
                    'status' => false,
                    'message' => 'Order tidak ditemukan',
                ], 404);
            }

            return response()->json([
                'status' => true,
                'message' => 'Berhasil mengambil detail order',
                'data' => $order,
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' =>
                'Gagal mengambil data: ' .
                    $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update the specified resource in storage.
     */
    public function updateStatus(Request $request, string $id)
    {
        $validator = Validator::make($request->all(), [
            'is_order_complete' => 'required|integer',
        ]);

        if ($validator->fails()) {

            return response()->json([
                'status' => false,
                'message' => 'Validasi gagal',
                'data' => $validator->errors(),
            ], 400);
        }

        try {

            $order = Order::find($id);

            if (!$order) {

                return response()->json([
                    'status' => false,
                    'message' => 'Order tidak ditemukan',
                ], 404);
            }

            $order->is_order_complete =
                $request->is_order_complete;

            // jika selesai dan belum ada waktu selesai
            if (
                $request->is_order_complete == 3 &&
                $order->transaction_complete_time == null
            ) {

                $order->transaction_complete_time =
                    Carbon::now()->format('Y-m-d H:i:s');
            }

            $order->save();

            return response()->json([
                'status' => true,
                'message' => 'Status order berhasil diupdate',
                'data' => $order,
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Gagal update status: ' . $e->getMessage(),
            ], 500);
        }
    }
    public function getOrderItems(string $id)
    {
        try {

            $items = \DB::table('order_items as oi')
                ->join(
                    'products as p',
                    'p.id',
                    '=',
                    'oi.products_id'
                )
                ->where('oi.order_id', $id)
                ->select(
                    'oi.*',
                    'p.name as product_name'
                )
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Berhasil mengambil order item',
                'data' => $items,
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Gagal mengambil data: ' . $e->getMessage(),
            ], 500);
        }
    }
    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        try {

            $order = Order::find($id);

            if (!$order) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order tidak ditemukan',
                ], 404);
            }

            $order->delete();

            return response()->json([
                'status' => true,
                'message' => 'Order berhasil dihapus',
            ], 200);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => 'Gagal menghapus order: ' . $e->getMessage(),
            ], 500);
        }
    }
    public function countByStatus()
    {
        try {

            $query = Order::where(function ($query) {

                $query->where('is_order_complete', '!=', 3)

                    ->orWhere('is_payment_complete', 0)

                    ->orWhere(function ($q) {

                        $q->where('is_order_complete', 3)
                            ->where('is_payment_complete', 1)
                            ->where(
                                'updated_at',
                                '>=',
                                Carbon::now()->subHours(24)
                            );
                    });
            });

            $data = [
                (clone $query)->where('is_order_complete', 0)->count(),
                (clone $query)->where('is_order_complete', 1)->count(),
                (clone $query)->where('is_order_complete', 2)->count(),
                (clone $query)->where('is_order_complete', 3)->count(),
            ];

            return response()->json([
                'status' => true,
                'data' => $data,
            ]);
        } catch (\Exception $e) {

            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }
}
