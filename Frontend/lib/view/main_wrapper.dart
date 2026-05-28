import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/view/customer_screen.dart';
import 'package:aplikasi_demo_test/view/login_screen.dart';
import 'package:aplikasi_demo_test/view/stock_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../service/api_service.dart';
import 'home_screen.dart';
import 'history_order/history_order.dart';
import 'setting_screen/screens/setting_screen.dart';

class Mainwrapper extends StatefulWidget {
  const Mainwrapper({super.key});

  @override
  State<Mainwrapper> createState() => _MainwrapperState();
}

class _MainwrapperState extends State<Mainwrapper> {
  int _selectedIndex = 0;
  final api = ApiService();

  final GlobalKey<HistoryOrderState> _inventoryKey =
      GlobalKey<HistoryOrderState>();
  late HistoryOrder inventoryScreen;

  @override
  void initState() {
    super.initState();
    inventoryScreen = HistoryOrder(key: _inventoryKey);
  }

  // *Fungsi untuk membangun daftar layar yang akan ditampilkan
  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      inventoryScreen,
      SettingScreen(
        onSyncSuccess: () {
          _inventoryKey.currentState?.refreshData();
        },
      ),
      CustomerScreen(),
      StockScreen(),
    ];
  }

  // *Fungsi untuk mengonfirmasi logout
  Future<void> _confirmLogout() async {
    AwesomeDialog(
      descTextStyle: TextStyle(fontSize: 30.sp),
      titleTextStyle: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w600),
      buttonsTextStyle: TextStyle(
        fontSize: 30.sp,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      context: context,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      title: "Logout",
      desc: "Apakah anda yakin untuk Logout?",
      dialogType: DialogType.warning,
      width: 400,
      headerAnimationLoop: false,
      dismissOnBackKeyPress: false,
      btnOkText: "Logout",
      btnOkOnPress: () {
        _logout();
      },
      btnCancelOnPress: () {},
    ).show();
  }

  // *Fungsi untuk logout dari aplikasi
  Future<void> _logout() async {
    try {
      await api.logout();
      await AuthService.logout();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      final message =
          e.toString().contains('timeout')
              ? 'Timeout Lebih dari 10 detik'
              : e.toString();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  // *Widget untuk membangun item navigasi
  Widget _buildNavItem({
    required Widget icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120.w,
        height: 90.h,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF486471) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          Container(
            width: 160.w,
            color: const Color.fromRGBO(36, 70, 82, 1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icon(Icons.home, color: Colors.white),
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _buildNavItem(
                  icon: Icon(Icons.history, color: Colors.white),
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildNavItem(
                  icon: Icon(Icons.settings, color: Colors.white),
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _buildNavItem(
                  icon: Center(
                    child: FaIcon(
                      FontAwesomeIcons.solidAddressBook,
                      color: Colors.white,
                    ),
                  ),
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _buildNavItem(
                  icon: Center(
                    child: FaIcon(
                      FontAwesomeIcons.boxArchive,
                      color: Colors.white,
                    ),
                  ),
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
                ElevatedButton(
                  onPressed: _confirmLogout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    enableFeedback: false,
                    iconSize: 30,
                    elevation: 0,

                    backgroundColor: const Color.fromRGBO(36, 70, 82, 1.0),
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    size: 24,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
