<?php

namespace App\Filament\Resources\StockInventoryResource\Pages;

use App\Filament\Resources\StockInventoryResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditStockInventory extends EditRecord
{
    protected static string $resource = StockInventoryResource::class;

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
