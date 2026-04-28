<?php

namespace App\Filament\Resources\PasswordResetRequestResource\Pages;

use App\Filament\Resources\PasswordResetRequestResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditPasswordResetRequest extends EditRecord
{
    protected static string $resource = PasswordResetRequestResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('kembali')
                ->label('Kembali')
                ->url($this->getResource()::getUrl('index')) // Mengarahkan ke daftar stok
                ->icon('heroicon-m-arrow-left'),

            Actions\DeleteAction::make(),
        ];
    }
}
