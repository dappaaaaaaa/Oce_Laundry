import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';

class StatusOrderWidget extends StatelessWidget {
  final int status;
  final String label;
  final Color? color;
  final int jumlah;

  const StatusOrderWidget({
    super.key,
    required this.status,
    required this.label,
    required this.jumlah,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color ?? AppColor.primary, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text(
            jumlah.toString(),
            style: const TextStyle(fontSize: 32, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
