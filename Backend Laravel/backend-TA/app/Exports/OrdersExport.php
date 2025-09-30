<?php

namespace App\Exports;

use App\Models\Order;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Carbon\Carbon;

class OrdersExport implements FromCollection, WithHeadings, ShouldAutoSize
{

    public function __construct()
    {
        Carbon::setLocale('id');
    }

    public function collection()
    {
        $orders = Order::with(['items.product'])
            ->orderBy('transaction_time', 'asc')
            ->get();

        $data = [];
        $no = 1;

        foreach ($orders as $order) {
            $productNames = $order->items->map(function ($item) {
                return $item->product->name ?? 'Produk tidak ditemukan';
            })->join(', ');

            $data[] = [
                'No' => $no++,
                'Customer Name' => $order->customer_name,
                'Phone Number' => $order->phone_number,
                'Cashier Name' => $order->cashier_name,
                'Total Item' => $order->total_item,
                'Sub Total' => $this->formatRupiah($order->sub_total),
                'Discount' => $order->discount,
                'Tax' => $order->tax,
                'Total' => $this->formatRupiah($order->total),
                'Payment Method' => match ((int) $order->payment_method) {
                    0 => 'Cash',
                    1 => 'Qris',
                    2 => 'Belum Bayar',
                    default => 'Tidak Diketahui',
                },
                'Total Payment' => $this->formatRupiah($order->total_payment),
                'Transaction Time' => Carbon::parse($order->transaction_time)->translatedFormat('d F Y,  H:i'),
                'Products' => $productNames,
            ];
        }

        return collect($data);
    }

    public function headings(): array
    {
        return [
            'No',
            'Nama Customer',
            'No. Hp',
            'Nama Kasir',
            'Total Item',
            'Sub Total',
            'Diskon',
            'Pajak',
            'Total',
            'Metode Pembayaran',
            'Total Pembayaran',
            'Waktu Transaksi',
            'Produk',
        ];
    }

    private function formatRupiah($amount)
    {
        return 'Rp ' . number_format($amount, 0, ',', '.');
    }
}
