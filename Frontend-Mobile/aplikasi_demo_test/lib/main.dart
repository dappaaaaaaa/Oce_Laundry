import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'view/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aplikasi_demo_test/view/navigation_screen.dart';

final storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await requestPermissions();
  final isLoggedIn = await AuthService.isLoggedIn();
  final userId = await AuthService.getUserId();
  runApp(MyApp(isLoggedIn: isLoggedIn, userId: userId));
}

// * Fungsi untuk meminta izin yang diperlukan
Future<void> requestPermissions() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.location,
  ].request();

  if (await Permission.bluetoothConnect.isDenied ||
      await Permission.bluetoothScan.isDenied ||
      await Permission.location.isDenied) {
    debugPrint("Beberapa izin penting ditolak!");
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int? userId;

  const MyApp({super.key, required this.isLoggedIn, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Qlaundry POS ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColor.backgroundColorPrimary,

        // * Menggunakan Google Fonts untuk tema teks
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.black,
          displayColor: AppColor.primary,
        ),
      ),

      // * Menentukan halaman awal berdasarkan status login
      home:
          isLoggedIn && userId != null
              ? NavigationScreen(userId: userId!)
              : LoginScreen(),
    );
  }
}
