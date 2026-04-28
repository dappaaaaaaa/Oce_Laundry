<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OrderResource\Pages;
use App\Filament\Resources\OrderResource\RelationManagers;
use App\Models\Order;
use Doctrine\DBAL\Schema\Schema;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Enums\ActionsPosition;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Filament\Tables\Actions\Action;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Repeater;
use App\Exports\OrdersExport;
use Maatwebsite\Excel\Facades\Excel;

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;
    protected static ?string $navigationLabel = 'Order';
    protected static ?string $pluralLabel = 'Order';
    protected static ?string $label = 'Order';
    protected static ?string $navigationGroup = 'Transaksi';
    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('customer_name')
                    ->label('Nama Customer')
                    ->required(),
                TextInput::make('phone_number')
                    ->label('No. HP')
                    ->default(0)
                    ->required(),
                DateTimePicker::make('transaction_time')
                    ->label('Waktu Transakasi')
                    ->required(),
                Repeater::make('items')
                    ->relationship()
                    ->label('Produk yang Dipesan')
                    ->reactive()
                    ->schema([
                        Select::make('products_id')
                            ->label('Produk')
                            ->searchable()
                            ->preload()
                            ->relationship(
                                'product',
                                'name',
                                modifyQueryUsing: fn($query) => $query->orderBy('id', 'asc')
                            )
                            ->required()
                            ->reactive()
                            ->afterStateUpdated(function ($state, callable $get, callable $set) {
                                $product = \App\Models\Product::find($state);
                                $weight = floatval($get('weight') ?? 0);
                                if ($product) {
                                    $price = $product->price * $weight;
                                    $set('price', $price);
                                }
                            }),

                        TextInput::make('weight')
                            ->label('Berat (kg)')
                            ->numeric()
                            ->required()
                            ->step(0.001)
                            ->reactive()
                            ->afterStateUpdated(function ($state, callable $get, callable $set) {
                                $product = \App\Models\Product::find($get('products_id'));
                                if ($product) {
                                    $price = $product->price * floatval($state);
                                    $set('price', $price);
                                }
                            }),

                        TextInput::make('price')
                            ->label('Harga')
                            ->numeric()
                            ->dehydrated()
                            ->required(),
                    ])
                    ->defaultItems(1)
                    ->columns(3)
                    ->createItemButtonLabel('Tambah Produk')
                    ->reactive()
                    ->afterStateUpdated(function ($state, callable $set, callable $get) {
                        self::recalculateTotals($set, $get);
                    }),
                TextInput::make('total_item')
                    ->label('Totla Item')
                    ->numeric()
                    ->disabled()
                    ->dehydrated()
                    ->reactive()
                    ->default(0),
                TextInput::make('sub_total')
                    ->label('Sub Total Transaksi')
                    ->numeric()
                    ->dehydrated()
                    ->reactive()
                    ->default(0),
                TextInput::make('discount')
                    ->label('Diskon')
                    ->numeric()
                    ->default(0),
                TextInput::make('tax')
                    ->label('Pajak')
                    ->numeric()
                    ->default(0),
                TextInput::make('total')
                    ->label('Total Transaksi')
                    ->numeric()
                    ->dehydrated()
                    ->reactive()
                    ->default(0),
                Select::make('payment_method')
                    ->label('Metode Pembayaran')
                    ->options([
                        0 => 'Cash',
                        1 => 'QRIS',
                    ])
                    ->default(0)
                    ->required(),
                TextInput::make('cashier_name')
                    ->label('Nama Kasir')
                    ->default('Kasir Qlaundry')
                    ->required(),

                TextInput::make('total_payment')
                    ->label('Total Pembayaran')
                    ->integer()
                    ->required(),
            ]);
    }

    protected static function recalculateTotals(callable $set, callable $get): void
    {
        $items = $get('items') ?? [];
        $subTotal = 0;

        foreach ($items as $item) {
            $subTotal += floatval($item['price'] ?? 0);
        }

        $totalItem = count($items);
        $discount = floatval($get('discount') ?? 0);
        $tax = floatval($get('tax') ?? 0);
        $total = $subTotal - $discount + $tax;

        $set('sub_total', $subTotal);
        $set('total_item', $totalItem);
        $set('total', $total);
    }

    protected function getHeaderActions(): array
    {
        return [];
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make("no")->label("No")->rowIndex(),
                TextColumn::make("customer_name")->label("Nama Customer")->searchable(),
                TextColumn::make("cashier_name")->label("Nama Kasir"),
                TextColumn::make("transaction_time")->label("Waktu Transaksi")->formatStateUsing(fn($state) => \Carbon\Carbon::parse($state)->translatedFormat('l, d F Y')),
                TextColumn::make("total")->money('Rp.', true)->label("Total"),
                TextColumn::make("total_payment")->money('Rp.', true)->label("Total Pembayaran"),
                TextColumn::make("total_item")->label("Total Item"),
                TextColumn::make("payment_method")
                    ->formatStateUsing(fn($state) => match ((int) $state) {
                        0 => 'Cash',
                        1 => 'Qris',
                        2 => 'Belum Bayar',
                        default => 'Tidak Diketahui',
                    })
                    ->label("Metode Pembayaran"),

            ])

            ->filters([
                Tables\Filters\Filter::make('transaction_time')
                    ->form([
                        Forms\Components\DatePicker::make('from')->label('Dari'),
                        Forms\Components\DatePicker::make('until')->label('Sampai'),

                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['from'],
                                fn(Builder $query, $date): Builder => $query->whereDate('transaction_time', '>=', $date),
                            )
                            ->when(
                                $data['until'],
                                fn(Builder $query, $date): Builder => $query->whereDate('transaction_time', '<=', $date),
                            );
                    })

            ]) #Setting default values
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),

            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ],);
    }
    public static function canViewAny(): bool
    {
        return auth()->user()->can('view_order');
    }

    public static function canCreate(): bool
    {
        return auth()->user()->can('create_order');
    }

    public static function canEdit($record): bool
    {
        return auth()->user()->can('update_order');
    }

    public static function canDelete($record): bool
    {
        return auth()->user()->can('delete_order');
    }

    public static function shouldRegisterNavigation(): bool
    {
        return auth()->user()->can('view_any_order'); // ganti sesuai permission
    }
    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->orderBy('transaction_time', 'asc');
    }
    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }
}
