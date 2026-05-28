<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Expenses;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class FinancialOverview extends BaseWidget{
    protected static ?int $sort = 1;
    protected function getStats(): array
    {
        $month = now()->month;
        $year  = now()->year;
        $income = Order::whereMonth('transaction_time', $month)
            ->whereYear('transaction_time', $year)
            ->where('is_order_complete', 3)
            ->sum('total');
        $estimatedIncome = Order::whereMonth('transaction_time', $month)
            ->whereYear('transaction_time', $year)
            ->where('is_order_complete', '!=', 3)
            ->sum('total');
        $unfinishedTransaction = Order::whereMonth('transaction_time', $month)
            ->whereYear('transaction_time', $year)
            ->where('is_order_complete', '!=', 3)
            ->where('is_payment_complete', 1)
            ->count();
        $expense = Expenses::whereMonth('date', $month)
            ->whereYear('date', $year)
            ->sum('amount');
        $profit = $income - $expense;
        return [
            Stat::make(
                "Pendapatan Bulan Ini",
                'Rp ' . number_format($income, 0, ',', '.')
            )
                ->description('Transaksi selesai')
                ->icon('heroicon-o-arrow-trending-up')
                ->color('success'),

            Stat::make(
                "Estimasi Pendapatan",
                'Rp ' . number_format($estimatedIncome, 0, ',', '.')
            )
                ->description('Dari transaksi belum selesai')
                ->icon('heroicon-o-clock')
                ->color('warning'),
            Stat::make(
                "Transaksi Belum Selesai",
                number_format($unfinishedTransaction, 0, ',', '.')
            )
                ->description('Masih dalam proses')
                ->icon('heroicon-o-shopping-bag')
                ->color('info'),
            Stat::make(
                'Pengeluaran Bulan Ini',
                'Rp ' . number_format($expense, 0, ',', '.')
            )
                ->icon('heroicon-o-arrow-trending-down')
                ->color('danger'),
            Stat::make(
                'Laba / Rugi Bulan Ini',
                'Rp ' . number_format($profit, 0, ',', '.')
            )
                ->description(
                    $profit >= 0
                        ? 'Keuntungan bulan ini'
                        : 'Kerugian bulan ini'
                )
                ->icon('heroicon-o-calculator')
                ->color($profit >= 0 ? 'success' : 'danger'),
        ];
    }
}
