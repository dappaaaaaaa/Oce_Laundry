import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// * Fungsi untuk membuat baris status pesanan
Widget orderStatusRow({
  required IconData icon,
  required Color color,
  required String text,
}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 40.sp),

        SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.black, fontSize: 30.sp)),
      ],
    ),
  );
}
