<?php

namespace App\Filament\Pages;

use App\Filament\Widgets\FinancialChart;
use App\Filament\Widgets\FinancialOverview;
use App\Models\Expenses;
use Filament\Pages\Page;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\DateRangePicker;
use Filament\Actions\Action;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Filament\Forms\Components\DatePicker;

class FinancialReport extends Page implements Forms\Contracts\HasForms
{
    use Forms\Concerns\InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?string $navigationLabel = 'Laporan Keuangan';
    protected static ?string $navigationGroup = 'Laporan';
    protected static string $view = 'filament.pages.financial-report';

    public $mode = 'monthly'; // monthly | custom
    public $month;
    public $year;
    public $periode;

    public $data = [];
    public ?string $start_date = null;
    public ?string $end_date = null;
    public function mount(): void
    {
        $this->month = now()->month;
        $this->year = now()->year;
        $this->periode = [now()->startOfMonth(), now()->endOfMonth()];
        $this->loadReport();
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Select::make('month')
                    ->options([
                        1 => 'Januari',
                        2 => 'Februari',
                        3 => 'Maret',
                        4 => 'April',
                        5 => 'Mei',
                        6 => 'Juni',
                        7 => 'Juli',
                        8 => 'Agustus',
                        9 => 'September',
                        10 => 'Oktober',
                        11 => 'November',
                        12 => 'Desember',
                    ])
                    ->label('Bulan')
                    ->reactive()
                    ->afterStateUpdated(fn() => $this->loadReport()),

                Select::make('year')
                    ->options(
                        collect(range(now()->year - 5, now()->year))
                            ->mapWithKeys(fn($y) => [$y => $y])
                    )
                    ->label('Tahun')
                    ->reactive()
                    ->afterStateUpdated(fn() => $this->loadReport()),

            ])->columns(2);
    }

    public function loadReport(): void
    {
        if ($this->start_date && $this->end_date) {
            $start = Carbon::parse($this->start_date)->startOfDay();
            $end   = Carbon::parse($this->end_date)->endOfDay();
        } else {
            $start = Carbon::create($this->year, $this->month, 1)->startOfMonth();
            $end   = (clone $start)->endOfMonth();
        }

        // Total Pendapatan
        $income = DB::table('orders')
            ->whereMonth('transaction_time', $this->month)
            ->whereYear('transaction_time', $this->year)
            ->sum('total');

        $expense = DB::table('expenses')
            ->whereMonth('date', $this->month)
            ->whereYear('date', $this->year)
            ->sum('amount');


        $this->data = [
            'income'  => $income,
            'expense' => $expense,
            'profit'  => $income - $expense,
            'start'   => $start,
            'end'     => $end,
        ];
    }



    public function exportPdf()
    {
        $income = DB::table('orders')
            ->whereMonth('transaction_time', $this->month)
            ->whereYear('transaction_time', $this->year)
            ->sum('total');

        $expense = DB::table('expenses')
            ->whereMonth('date', $this->month)
            ->whereYear('date', $this->year)
            ->sum('amount');

        $totalTransactions = DB::table('orders')
            ->whereMonth('transaction_time', $this->month)
            ->whereYear('transaction_time', $this->year)
            ->count();

        $topProducts = DB::table('order_items')
            ->join('products', 'order_items.products_id', '=', 'products.id')
            ->select(
                'products.name',
                DB::raw('ROUND(SUM(order_items.weight), 2) as total_qty'),
                DB::raw('SUM(order_items.weight * order_items.price) as total_income'),
                DB::raw('COUNT(order_items.id) as total_orders')
            )
            ->whereMonth('order_items.created_at', $this->month)
            ->whereYear('order_items.created_at', $this->year)
            ->groupBy('products.name')
            ->orderByDesc('total_qty')
            ->get();

        $orders = DB::table('orders')
            ->whereMonth('transaction_time', $this->month)
            ->whereYear('transaction_time', $this->year)
            ->get();

        $expenses = Expenses::with('category')
            ->whereMonth('date', $this->month)
            ->whereYear('date', $this->year)
            ->get();

        $pdf = Pdf::loadView('reports.financial', [
            'month'             => $this->month,
            'year'              => $this->year,
            'income'            => $income,
            'expense'           => $expense,
            'totalTransactions' => $totalTransactions,
            'orders'            => $orders,
            'expenses'          => $expenses,
            'topProducts'       => $topProducts,
        ]);


        return response()->streamDownload(
            fn() => print($pdf->output()),
            "laporan-keuangan-{$this->month}-{$this->year}.pdf"
        );
    }



    protected function getActions(): array
    {
        return [
            Action::make('export')
                ->label('Export PDF')
                ->icon('heroicon-o-arrow-down-tray')
                ->action('exportPdf'),
        ];
    }
}
