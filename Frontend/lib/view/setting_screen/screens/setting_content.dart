import 'package:aplikasi_demo_test/view/setting_screen/cubit/tax_discount_cubit.dart';
import 'package:aplikasi_demo_test/view/setting_screen/screens/printer_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../utils/app_color.dart';

class SettingContentWidget extends StatelessWidget {
  final String? selectedValue;
  final VoidCallback onSyncProduct;
  final VoidCallback onSyncTransaksi;
  final VoidCallback onSyncSuccess;

  const SettingContentWidget({
    super.key,
    required this.selectedValue,
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
              Gap(7),
              SizedBox(
                height: 100.h,
                width: double.infinity,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30.sp,
                        ),
                      ),
                      Icon(FontAwesome.rotate_solid, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
