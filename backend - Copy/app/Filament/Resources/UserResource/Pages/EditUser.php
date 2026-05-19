<?php

namespace App\Filament\Resources\UserResource\Pages;

use App\Filament\Resources\UserResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditUser extends EditRecord
{
    protected static string $resource = UserResource::class;

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


    public function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
