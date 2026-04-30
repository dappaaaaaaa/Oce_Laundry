<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ProductResource\Pages;
use App\Filament\Resources\ProductResource\RelationManagers;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Illuminate\Database\Eloquent\Builder;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;
    protected static ?string $navigationLabel = 'Produk';
    protected static ?string $pluralLabel = 'Produk';
    protected static ?string $label = 'Produk';
    protected static ?string $navigationGroup = 'Transaksi';
    protected static ?string $navigationIcon = 'heroicon-o-archive-box';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Select::make("category_id")
                    ->required()
                    ->relationship(name: 'category', titleAttribute: 'name')
                    ->placeholder("Select Category"),
                TextInput::make("name")
                    ->required(),
                TextInput::make("description")
                    ->required(),
                TextInput::make("price")
                    ->required()
                    ->integer()
                    ->step(1000),
                Select::make("status")
                    ->required()
                    ->options([
                        0 => 'Tidak Tersedia',
                        1 => 'Tersedia'
                    ])
                    ->default(1)
                    ->selectablePlaceholder(false),

                // FileUpload::make('image')
                //     ->directory("category")
                //     ->visibility('public')
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make("category.name"),
                TextColumn::make("name"),
                TextColumn::make("description"),
                TextColumn::make("price")
                    ->money("IDR"),
                TextColumn::make("status")
                    ->formatStateUsing(fn($state) => $state == 1 ? 'Tersedia' : 'Tidak Tersedia'),
                // ImageColumn::make('image'),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make()
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }
    public static function canViewAny(): bool
    {
        return auth()->user()->can('view_product');
    }

    public static function canCreate(): bool
    {
        return auth()->user()->can('create_product');
    }

    public static function canEdit($record): bool
    {
        return auth()->user()->can('update_product');
    }

    public static function canDelete($record): bool
    {
        return auth()->user()->can('delete_product');
    }

    public static function shouldRegisterNavigation(): bool
    {
        return auth()->user()->can('view_any_product'); // ganti sesuai permission
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
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }
}
