import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'midtrans_payment_screen.dart';

class UpdatePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const UpdatePaymentScreen({super.key, required this.orderData});

  @override
  State<UpdatePaymentScreen> createState() => _UpdatePaymentScreenState();
}

class _UpdatePaymentScreenState extends State<UpdatePaymentScreen> {
  final TextEditingController _paymentController = TextEditingController();
  int _selectedPaymentMethod = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  // * Fungsi untuk mengelola proses pembayaran berdasarkan metode yang dipilih
  Future<void> _handlePayment() async {
    final db = DatabaseHelper();
    final total =
        widget.orderData['total'] - widget.orderData['total_payment'] as int;

    final inputText = _paymentController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final totalInput = int.tryParse(inputText) ?? 0;

    if (_selectedPaymentMethod == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => MidtransPaymentScreen(
                amount: total,
                customerName: widget.orderData['customer_name'],
                customerPhone: widget.orderData['phone_number'],
              ),
        ),
      );

      // * Memeriksa apakah pembayaran berhasil
      if (result == true) {
        final updatedPayment = widget.orderData['total_payment'] + total;
        await db.updateOrderPayment(
          widget.orderData['id'],
          updatedPayment,
          1,
          1,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran QRIS berhasil')),
        );
      }
    } else {
      if (totalInput < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah pembayaran kurang dari sisa total'),
          ),
        );
        return;
      }

      final updatedPayment = widget.orderData['total_payment'] + totalInput;
      await db.updateOrderPayment(widget.orderData['id'], updatedPayment, 1, 0);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        widget.orderData['total'] - widget.orderData['total_payment'] as int;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColor.backgroundColorPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              height: 550,
              width: 400,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  style: BorderStyle.solid,
                  color: AppColor.primary,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Nama: ${widget.orderData['customer_name']}"),
                    Text("Total Sisa Pembayaran: ${formatter.format(total)}"),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 340,
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            borderRadius: BorderRadius.circular(8),
                            value: _selectedPaymentMethod,
                            dropdownColor: AppColor.backgroundColorPrimary,

                            items: const [
                              DropdownMenuItem(value: 0, child: Text("Cash")),
                              DropdownMenuItem(value: 1, child: Text("QRIS")),
                            ],
                            onChanged: (value) {
                              setState(
                                () => _selectedPaymentMethod = value ?? 0,
                              );
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: AppColor.primary,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              focusColor: AppColor.primary,
                              labelStyle: TextStyle(color: Colors.black),
                              fillColor: AppColor.backgroundColorPrimary,
                              labelText: "Metode Pembayaran",
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_selectedPaymentMethod == 0)
                            TextFormField(
                              controller: _paymentController,
                              keyboardType: TextInputType.number,
                              decoration: CustomTextFieldStyle.inputDecoration(
                                labelText: 'Jumlah Pembayaran',
                              ),
                              onChanged: (value) {
                                final digitsOnly = value.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                final intVal = int.tryParse(digitsOnly) ?? 0;
                                final formatted = formatter.format(intVal);
                                _paymentController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 16),
                          if (_selectedPaymentMethod == 0)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: () {
                                final List<int> preset = [
                                  5000,
                                  10000,
                                  20000,
                                  40000,
                                  50000,
                                  100000,
                                ];

                                final List<int> amounts = [
                                  total,
                                  ...preset.where((value) => value != total),
                                ];
                                final List<int> displayAmounts =
                                    amounts.take(6).toList();
                                return displayAmounts.map((amount) {
                                  final isExact = amount == total;
                                  return ElevatedButton(
                                    onPressed: () {
                                      final formatted = formatter.format(
                                        amount,
                                      );
                                      _paymentController.text = formatted;
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      isExact
                                          ? "Uang Pas"
                                          : formatter.format(amount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList();
                              }(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              maximumSize: Size(200, 80),
                              minimumSize: Size(150, 60),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.payment),
                            label: const Text(
                              "Bayar Sekarang",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _handlePayment,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              maximumSize: Size(200, 80),
                              minimumSize: Size(150, 60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
