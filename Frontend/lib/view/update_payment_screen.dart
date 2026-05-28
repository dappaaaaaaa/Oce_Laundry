import 'package:aplikasi_demo_test/database/order.dart';
import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class UpdatePaymentScreen extends StatefulWidget {
  final Order orderData;

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
    final api = ApiService();
    final token = AuthService.getToken();
    final total = widget.orderData.total - widget.orderData.totalPayment;

    final inputText = _paymentController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final totalInput = int.tryParse(inputText) ?? 0;

    setState(() {
      // _isLoading = true;
    });

    try {
      // =========================
      // QRIS
      // =========================
      if (_selectedPaymentMethod == 1) {
        final updatedPayment = widget.orderData.totalPayment + total;

        final success = await api.updateOrderPayment(
          widget.orderData.id,
          updatedPayment,
          1,
          1,
          await token ?? "",
        );

        if (!success) {
          throw Exception("Gagal update pembayaran QRIS");
        }

        if (!mounted) return;

        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran QRIS berhasil')),
        );

        return;
      }

      // =========================
      // CASH
      // =========================
      if (totalInput < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah pembayaran kurang dari sisa total'),
          ),
        );

        return;
      }

      final updatedPayment = widget.orderData.totalPayment + totalInput;

      final success = await api.updateOrderPayment(
        widget.orderData.id,
        updatedPayment,
        1,
        0,
        await token ?? "",
      );

      if (!success) {
        throw Exception("Gagal update pembayaran");
      }

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.orderData.total - widget.orderData.totalPayment;
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
                    Text(
                      "Nama: ${widget.orderData.customerName}",
                      style: TextStyle(fontSize: 30.sp),
                    ),
                    Text(
                      "Total Sisa Pembayaran: ${formatter.format(total)}",
                      style: TextStyle(fontSize: 30.sp),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            borderRadius: BorderRadius.circular(8),
                            value: _selectedPaymentMethod,
                            dropdownColor: AppColor.backgroundColorPrimary,

                            items: [
                              DropdownMenuItem(
                                value: 0,
                                child: Text(
                                  "Cash",
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  "QRIS",
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                              ),
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
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 30.sp,
                              ),
                              fillColor: AppColor.backgroundColorPrimary,
                              labelText: "Metode Pembayaran",
                            ),
                          ),
                          SizedBox(height: 20),
                          if (_selectedPaymentMethod == 0)
                            TextFormField(
                              style: TextStyle(fontSize: 30.sp),
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
                              spacing: 6,
                              runSpacing: 6,
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
                                      minimumSize: Size(280.w, 70.h),
                                      maximumSize: Size(300.w, 100.h),
                                      backgroundColor: AppColor.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      isExact
                                          ? "Uang Pas"
                                          : formatter.format(amount),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30.sp,
                                      ),
                                    ),
                                  );
                                }).toList();
                              }(),
                            ),
                        ],
                      ),
                    ),
                    Gap(20),
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
                              minimumSize: Size(430.w, 80.h),
                              maximumSize: Size(450.w, 100.h),
                            ),
                            child: Text(
                              "Batal",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32.sp,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.payment),
                            label: Text(
                              "Bayar Sekarang",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32.sp,
                              ),
                            ),
                            onPressed: _handlePayment,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: Size(430.w, 80.h),
                              maximumSize: Size(450.w, 100.h),
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
