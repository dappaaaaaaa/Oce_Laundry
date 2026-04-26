<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ExpenseResource\Pages;
use App\Models\Expenses;
use Filament\Forms;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ExpenseResource extends Resource
{
    protected static ?string $model = Expenses::class;

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';
    protected static ?string $navigationLabel = 'Pengeluaran';
    protected static ?string $pluralLabel = 'Pengeluaran';
    protected static ?string $navigationGroup = 'Pengeluaran';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Select::make("expenses_category_id")
                    ->required()
                    ->relationship(name: 'category', titleAttribute: 'name')
                    ->placeholder("Pilih Kategori")
                    ->label("Kategori"),

                DatePicker::make("date")->label("Tanggal Dan Waktu")->required(),

                Textarea::make("description")->required()->label("Deskripsi Pengeluaran"),

                TextInput::make("amount")
                    ->label("Total Pengeluaran")
                    ->numeric()
                    ->required(),
                Repeater::make('items')
                    ->relationship('items')
                    ->label('Detail Item Pengeluaran')
                    ->columnSpanFull()
                    ->schema([
                        TextInput::make('item_name')
                            ->label('Nama Barang')
                            ->required(),

                        TextInput::make('qty')
                            ->numeric()
                            ->default(1)
                            ->required()
                            ->label('Qty')
                            ->reactive()
                            ->afterStateUpdated(function ($state, callable $set, callable $get) {
                                $set('total', ($get('qty') ?? 1) * ($get('price') ?? 0));

                                self::updateAmount($set, $get);
                            }),

                        TextInput::make('price')
                            ->numeric()
                            ->required()
                            ->label('Harga')
                            ->reactive()
                            ->afterStateUpdated(function ($state, callable $set, callable $get) {
                                $set('total', ($get('qty') ?? 1) * ($get('price') ?? 0));

                                self::updateAmount($set, $get);
                            }),

                        TextInput::make('total')
                            ->numeric()
                            ->label('Total')
                            ->disabled()
                            ->dehydrated(true)
                            ->reactive(),
                    ])
                    ->columns(4)
                    ->createItemButtonLabel('Tambah Item')
                    ->afterStateUpdated(function ($state, callable $set) {
                        $set('amount', collect($state ?? [])->sum(function ($item) {
                            $qty   = isset($item['qty']) ? (int) preg_replace('/[^\d.]/', '', $item['qty']) : 1;
                            $price = isset($item['price']) ? (int) preg_replace('/[^\d.]/', '', $item['price']) : 0;
                        
                            return $qty * $price;
                        }));
                        
                    }),

            ]);
    }

    protected static function updateAmount(callable $set, callable $get): void
    {
        $items = $get('../../items');
        $total = collect($items)->sum(fn($item) => ($item['qty'] ?? 1) * ($item['price'] ?? 0));
        $set('../../amount', $total);
    }


    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make("no")->label("No")->rowIndex(),
                TextColumn::make("category.name")->label("Kategori"),
                TextColumn::make("date")
                    ->label("Tanggal Pengeluaran")
                    ->formatStateUsing(fn($state) => \Carbon\Carbon::parse($state)->translatedFormat('l, d F Y')),
                TextColumn::make("description")->label("Deskripsi"),
                TextColumn::make('items')
                    ->label('Daftar Item')
                    ->formatStateUsing(
                        fn($record) =>
                        $record->items->map(fn($item) => "{$item->item_name} ({$item->qty}x)")
                            ->implode(', ')
                    )
                    ->wrap(),

                TextColumn::make("amount")->label("Total Pengeluaran")->money('IDR'),
            ])
            ->filters([])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            // kalau mau tab khusus juga bisa bikin RelationManager di sini
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListExpenses::route('/'),
            'create' => Pages\CreateExpense::route('/create'),
            'edit' => Pages\EditExpense::route('/{record}/edit'),
        ];
    }
}
