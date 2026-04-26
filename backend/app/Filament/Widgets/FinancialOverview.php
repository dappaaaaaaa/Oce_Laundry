<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Expenses;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class FinancialOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $month = now()->month;
        $year  = now()->year;


        $income = Order::whereMonth('transaction_time', $month)
            ->whereYear('transaction_time', $year)
            ->sum('total');


        $expense = Expenses::whereMonth('date', $month)
            ->whereYear('date', $year)
            ->sum('amount');

        $profit = $income - $expense;

        return [
            Stat::make("Pendapatan Bulan Ini", 'Rp ' . number_format($income, 0, ',', '.'))
                ->icon('heroicon-o-arrow-up-circle')
                ->color('success'),


            Stat::make('Pengeluaran Bulan Ini', 'Rp ' . number_format($expense, 0, ',', '.'))
                ->icon('heroicon-o-arrow-down-circle')
                ->color('danger'),

            Stat::make('Laba / Rugi Bulan Ini', 'Rp ' . number_format($profit, 0, ',', '.'))
                ->icon('heroicon-o-calculator')
                ->color($profit >= 0 ? 'success' : 'danger'),
        ];
    }
}
