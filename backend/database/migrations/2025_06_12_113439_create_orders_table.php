<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->integer("total_payment");
            $table->integer("sub_total");
            $table->integer("tax");
            $table->integer("discount");
            $table->integer("total");
            $table->integer("total_item");
            $table->string("payment_method");
            $table->dateTime("transaction_time");
            $table->dateTime("transaction_complete_time");
            $table->string("customer_name");
            $table->string("phone_number");
            $table->string("cashier_name");
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
