<?php

namespace App\Filament\Resources\PasswordResetRequestResource\Pages;

use App\Filament\Resources\PasswordResetRequestResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreatePasswordResetRequest extends CreateRecord
{
    protected static string $resource = PasswordResetRequestResource::class;
}
