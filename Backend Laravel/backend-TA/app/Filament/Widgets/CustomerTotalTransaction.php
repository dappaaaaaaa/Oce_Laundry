<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\DB;
class CustomerTotalTransaction extends ChartWidget
{
    protected static ?string $heading = 'Pelanggan dengan Transaksi Terbanyak';
    protected static ?int $sort = 4;

    protected function getFilters(): ?array
    {
        return [
            'count' => 'Jumlah Transaksi',
            'sum' => 'Total Transaksi',
        ];
    }
    public static function canView(): bool
    {
        return auth()->user()->can('widget_CustomerTotalTransaction');
    }
    public function getDescription(): ?string
    {
        return 'Diagram ini menunjukan Pelanggan yang paling banyak melakukan transaksi';
    }

    
    protected function getData(): array
    {
    
            $filter = $this->filter ?? 'count';
            switch($filter){
            	case 'count':        
	        		$data = DB::table('orders')
	            	->whereNotNull('customer_name')
	            	->select('customer_name', DB::raw('COUNT(*) as total'))
	            	->groupBy('customer_name')
	            	->orderByDesc('total')
	            	->limit(10)
	            	->get();
	            	break;

            	case 'sum':
	            	$data = DB::table('orders')
		            ->whereNotNull('customer_name')
		            ->select('customer_name', DB::raw('SUM(total) as total'))
		            ->groupBy('customer_name')
		            ->orderByDesc('total')
		            ->limit(10)
		            ->get();
		            break;
}					
	
        return [
            'datasets' => [
                [
                    'label' => 'Jumlah Transaksi',
                    'data' => $data->pluck('total'),
                    'backgroundColor' => [
                        '#f87171', '#fbbf24', '#34d399', '#60a5fa', '#a78bfa',
                        '#f472b6', '#facc15', '#10b981', '#3b82f6', '#8b5cf6',
                    ],
                ],
            ],
            'labels' => $data->pluck('customer_name'),
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
