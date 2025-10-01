<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\DB;
class ProductSales extends ChartWidget
{	
    protected static ?string $heading = 'Penjualan Produk';
    protected static ?int $sort = 3;

    public function getDescription(): ?string
    {
        return 'Diagram ini menunjukan Produk yang paling banyak terjual';
    }

    public static function canView(): bool
    {
        return auth()->user()->can('widget_ProductSales');
    }
    protected function getData(): array
    {
        $data = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.products_id', '=', 'products.id')
            ->whereNotNull('orders.customer_name')
            ->select('products.name', DB::raw('COUNT(order_items.id) as total'))
            ->groupBy('products.name')
            ->orderByDesc('total')
            ->limit(6)
            ->get();

        return [
            'datasets' => [
                [
                    'label' => 'Jumlah Dipesan',
                    'data' => $data->pluck('total'),
                    'backgroundColor' => [
                        '#f87171', '#fbbf24', '#34d399', '#60a5fa', '#a78bfa',
                        '#f472b6', '#facc15', '#10b981', '#3b82f6', '#8b5cf6',
                    ],
                ],
            ],
            'labels' => $data->pluck('name'),
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
