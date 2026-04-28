<?php

namespace App\Filament\Resources;

use App\Filament\Resources\StockInventoryResource\Pages;
use App\Filament\Resources\StockInventoryResource\RelationManagers;
use App\Models\StockInventory;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

use function Laravel\Prompts\text;

class StockInventoryResource extends Resource
{
    protected static ?string $model = StockInventory::class;
    protected static ?string $navigationLabel = 'Stok';
    protected static ?string $pluralLabel = 'Stok';
    protected static ?string $label = 'Stok';
    protected static ?string $navigationGroup = 'Inventarisasi Stok';
    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('nama')
                    ->required(),
                Forms\Components\TextInput::make('kuantitas')
                    ->numeric()
                    ->required(),
                Forms\Components\Textarea::make('keterangan'),
                Forms\Components\FileUpload::make('image')
                    ->directory("stock")
                    ->acceptedFileTypes(['image/jpeg', 'image/png', 'image/jpg', 'image/heic', 'image/gif']) // 
                    ->visibility('public')
                    ->preserveFilenames()
                    ->extraInputAttributes([
                        'capture' => 'environment', // 'environment' untuk kamera belakang, 'user' untuk kamera depan

                    ])
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make("nama"),
                TextColumn::make("kuantitas"),
                TextColumn::make("keterangan"),
                ImageColumn::make("image")
            ])
            ->filters([
                //
            ])
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
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListStockInventories::route('/'),
            'create' => Pages\CreateStockInventory::route('/create'),
            'edit' => Pages\EditStockInventory::route('/{record}/edit'),
        ];
    }
}
