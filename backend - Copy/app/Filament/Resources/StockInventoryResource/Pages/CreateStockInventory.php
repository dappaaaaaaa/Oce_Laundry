<?php

namespace App\Filament\Resources\StockInventoryResource\Pages;

use App\Filament\Resources\StockInventoryResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateStockInventory extends CreateRecord
{
    protected static string $resource = StockInventoryResource::class;

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }

    protected function getCreatedNotificationTitle(): ?string
    {
        return 'Stok berhasil disimpan!';
    }
}
