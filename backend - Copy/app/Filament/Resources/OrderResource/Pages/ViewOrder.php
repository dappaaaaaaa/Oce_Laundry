<?php

namespace App\Filament\Resources\OrderResource\Pages;

use App\Filament\Resources\OrderResource;
use Filament\Resources\Pages\ViewRecord;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Panel;
use Filament\Panel as FilamentPanel;
use Filament\Tables\Columns\Layout\Panel as LayoutPanel;

class ViewOrder extends ViewRecord
{
    protected static string $resource = OrderResource::class;

    protected function getHeaderWidgets(): array
    {
        return [];
    }

    protected function getFooterWidgets(): array
    {
        return [
            // FilamentPanel::make()
            //     ->heading('Detail Produk yang Dipesan')
            //     ->view('filament.resources.orders.view-items', [
            //         'items' => $this->record->items,
            //     ]),
        ];
    }
}
