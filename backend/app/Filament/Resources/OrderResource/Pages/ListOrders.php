<?php

namespace App\Filament\Resources\OrderResource\Pages;

use App\Filament\Resources\OrderResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;
use Filament\Pages\Actions\Action;

class ListOrders extends ListRecords
{
    protected static string $resource = OrderResource::class;

    protected function getHeaderActions(): array
    {
	return [
		Actions\CreateAction::make(),
		Action::make('Export Excel')
		->label('Export Excel')
		->color('success')
		->icon('heroicon-o-arrow-up-tray')
		->url(fn () => route('orders.export.excel'))
		->openUrlInNewTab(),
        ];
    }
}
