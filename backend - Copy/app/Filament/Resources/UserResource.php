<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Components\DateTimePicker;
use Filament\Resources\Resource;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Forms\Components\TextInput;
use Illuminate\Database\Eloquent\Builder;
use Filament\Forms\Components\Select;

class UserResource extends Resource
{
    protected static ?string $model = User::class;
    protected static ?string $navigationLabel = 'User';
    protected static ?string $pluralLabel = 'User';
    protected static ?string $label = 'User';
    protected static ?string $navigationIcon = 'heroicon-o-user';
    protected static ?string $navigationGroup = 'Manajemen User';
    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make("name")->required()->label("Nama Lengkap"),
                TextInput::make("email")->required()->label("Email")
                    ->email(),
                TextInput::make("password")
                    ->required(fn(string $context): bool => $context === 'create')
                    ->dehydrated(fn($state) => filled($state))
                    ->label("Kata Sandi")
                    ->password(),

                Select::make('roles')
                    ->label('Role')
                    ->relationship('roles', 'name', modifyQueryUsing: function ($query) {
                        if (!auth()->user()->hasRole('super_admin')) {
                            $query->where('name', '!=', 'super_admin');
                        }
                    })
                    ->preload()
                    ->required(),

            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make("email"),
                TextColumn::make("name"),
                TextColumn::make('roles.name')
                    ->label('Role')
                    ->badge(),

            ])
            ->filters([])
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
    public static function shouldRegisterNavigation(): bool
    {
        return auth()->user()->can('view_any_user');
    }

    public static function canViewAny(): bool
    {
        return auth()->user()->can('view_user');
    }

    public static function canCreate(): bool
    {
        return auth()->user()->can('create_user');
    }

    public static function canEdit($record): bool
    {
        return auth()->user()->can('update_user');
    }

    public static function canDelete($record): bool
    {
        return auth()->user()->can('delete_user');
    }

    public static function getEloquentQuery(): Builder
    {
        $query = parent::getEloquentQuery();

        if (!auth()->user()->hasRole('super_admin')) {
            $query->whereDoesntHave('roles', function ($q) {
                $q->where('name', 'super_admin');
            });
        }

        return $query;
    }
    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
