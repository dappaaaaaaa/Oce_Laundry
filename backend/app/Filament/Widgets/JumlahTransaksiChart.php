<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

class JumlahTransaksiChart extends ChartWidget
{
    protected static ?string $heading = null;
    protected static ?int $sort = 2;
    public ?string $filter = 'week';

    public function getHeading(): ?string
    {
        $now = Carbon::now('Asia/Jakarta');
        $bulan = $now->translatedFormat('F');
        $tahun = $now->year;
    
        return "Jumlah Transaksi - $bulan $tahun";
    }
    public static function canView(): bool
    {
        return auth()->user()->can('widget_JumlahTransaksiChart');
    }
    
    protected function getFilters(): ?array
    {
        return [
            'week' => 'Minggu ini',
            'month' => 'Bulan ini',
            'year' => 'Tahun ini',
        ];
    }

    public function getDescription(): ?string
    {
        $filter = $this->filter ?? 'week';
        switch ($filter) {
            case 'month':
                return 'Diagram ini menunjukan Jumlah transaksi yang dilakukan untuk Bulan ini';
                break;
            case 'year':
                return 'Diagram ini menunjukan Jumlah transaksi yang dilakukan untuk Tahun ini';
                break;
            case 'week':
                return 'Diagram ini menunjukan Jumlah transaksi yang dilakukan untuk Minggu ini';
            default:
                return '';
                break;
        }
    }

    protected function getData(): array
    {
        $now = now('Asia/Jakarta');
        $filter = $this->filter ?? 'week';

        switch ($filter) {
            case 'month':
                $start = $now->copy()->startOfMonth();
                $end = $now->copy()->endOfMonth();
                $interval = 'perDay'; 
                $weeksInMonth = $start->diffInWeeks($end) + 1;
                $labels = [];
                for ($i = 1; $i <= $weeksInMonth; $i++) {
                    $labels[] = "Minggu ke-$i";
                }
                $labelFormat = function ($date) use ($start) {
                    $date = Carbon::parse($date);
                    // Hitung minggu ke-berapa dalam bulan berdasarkan kalender
                    $firstDayOfMonth = $start->copy()->startOfWeek();
                    $weekIndex = floor($date->diffInDays($firstDayOfMonth) / 7);
                    return $weekIndex;
                };
                
                break;
            
            case 'year':
                $start = $now->copy()->startOfYear();
                $end = $now->copy()->endOfYear();
                $interval = 'perMonth';
                $labels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                $labelFormat = fn ($date) => Carbon::parse($date)->month - 1;
                break;

            case 'week':
            default:
                $start = $now->copy()->startOfWeek();
                $end = $now->copy()->endOfWeek();
                $interval = 'perDay';
                $labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                $labelFormat = fn ($date) => Carbon::parse($date)->dayOfWeekIso - 1;
                break;
        }
        $query = Trend::model(Order::class)
            ->dateColumn('transaction_time')
            ->between(start: $start, end: $end);
        $query = $query->{$interval}()->count();
        $mapped = collect(array_fill(0, count($labels), 0));
        foreach ($query as $trend) {
            $index = $labelFormat($trend->date);
            if (isset($mapped[$index])) {
                $mapped[$index] += $trend->aggregate;
            }
        }

        return [
            'datasets' => [
                [
                    'label' => 'Jumlah Transaksi',
                    'data' => $mapped->values()->toArray(),
                    'backgroundColor' => 'rgba(54, 162, 235, 0.5)',
                    'borderColor' => 'rgba(54, 162, 235, 1)',
                    'borderWidth' => 1,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
