<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PasswordResetRequestResource\Pages;
use App\Models\PasswordResetRequest;
use Filament\Forms;
use Filament\Tables;
use Filament\Resources\Resource;
use Illuminate\Support\Facades\Hash;

class PasswordResetRequestResource extends Resource
{
    protected static ?string $model = PasswordResetRequest::class;

    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static ?string $navigationLabel = 'Request Reset Password';
    protected static ?string $navigationGroup = 'Manajemen User';

    public static function form(Forms\Form $form): Forms\Form
    {
        return $form->schema([
            Forms\Components\Select::make('user_id')
                ->relationship('user', 'email')
                ->disabled(),
            Forms\Components\TextInput::make('status')->disabled(),
        ]);
    }

    public static function table(Tables\Table $table): Tables\Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')->sortable(),
                Tables\Columns\TextColumn::make('user.name')->label('User'),
                Tables\Columns\TextColumn::make('user.email')->label('Email'),
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'warning' => 'pending',
                        'success' => 'done',
                    ]),
                Tables\Columns\TextColumn::make('created_at')->dateTime('d M Y H:i'),
            ])
            ->filters([])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\Action::make('approve')
                    ->label('Approve & Reset')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->visible(fn($record) => $record->status === 'pending')
                    ->requiresConfirmation()
                    ->action(function ($record) {
                        $user = $record->user;
                        $user->password = Hash::make('123456');
                        $user->save();

                        $record->status = 'done';
                        $record->save();
                    }),
            ]);
    }
    
    public static function shouldRegisterNavigation(): bool
    {
        return auth()->user()->can('view_any_password::reset::request'); // ganti sesuai permission
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPasswordResetRequests::route('/'),
        ];
    }
}
