import 'package:aplikasi_demo_test/view/setting_screen/cubit/tax_discount_cubit.dart';
import 'package:aplikasi_demo_test/view/setting_screen/screens/printer_content.dart';
import 'package:aplikasi_demo_test/view/setting_screen/screens/tax_discount_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../utils/app_color.dart';

class SettingContentWidget extends StatelessWidget {
  final String? selectedValue;
  final String username;
  final VoidCallback onSyncProduct;
  final VoidCallback onSyncTransaksi;
  final VoidCallback onSyncSuccess;

  const SettingContentWidget({
    super.key,
    required this.selectedValue,
    required this.username,
    required this.onSyncProduct,
    required this.onSyncTransaksi,
    required this.onSyncSuccess,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedValue) {
      case 'Kelola Printer':
        return PrinterContent();
      case 'Sinkroniasi':
        return SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                width: 370,
                child: ElevatedButton(
                  onPressed: onSyncProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Sinkronisasi Produk Dari Server Ke Lokal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Icon(FontAwesome.rotate_solid),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5),
              SizedBox(
                height: 100,
                width: 370,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            backgroundColor: AppColor.backgroundColorPrimary,
                            content: const Text(
                              'Apakah Anda yakin ingin sinkronisasi data transaksi?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(color: AppColor.primary),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  maximumSize: Size(80, 50),
                                  minimumSize: const Size(80, 50),
                                ),
                                child: const Text('Ya'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) onSyncTransaksi();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Sinkronisasi Transaksi dari Lokal Ke Server',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Icon(FontAwesome.cloud_arrow_up_solid),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 'Kelola Pajak & Diskon':
        return BlocProvider(
          create: (_) => TaxDiscountCubit()..loadData(),
          child: TaxDiscountSection(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
