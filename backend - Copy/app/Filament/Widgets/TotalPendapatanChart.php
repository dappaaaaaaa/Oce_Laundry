<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

class TotalPendapatanChart extends ChartWidget
{
    protected static ?string $heading = 'Total Pendapatan';
    protected static string $color = 'primary';
    protected static ?int $sort = 1;
    public function getDescription(): ?string
    {
        return 'Diagram ini menunjukan Total Pendapatan per Bulan';
    }
    public static function canView(): bool
    {
        return auth()->user()->can('widget_TotalPendapatanChart');
    }
    protected function getData(): array
    {
        $data = Trend::model(Order::class)
            ->dateColumn('transaction_time')
            ->between(
                start: now()->startOfYear(),
                end: now()->endOfYear(),
            )
            ->perMonth()
            ->sum("total");

        return [
            'datasets' => [
                [
                    'label' => 'Total Pendapatan',
                    'data' => $data->map(fn(TrendValue $value) => $value->aggregate),
                    'backgroundColor' => '#36A2EB',
                    'borderColor' => '#9BD0F5',
                ],
            ],
            'labels' => $data->map(fn(TrendValue $value) => \Carbon\Carbon::parse($value->date)->format('M'))
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
