import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/view/customer_screen.dart';
import 'package:aplikasi_demo_test/view/login_screen.dart';
import 'package:aplikasi_demo_test/view/stock_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../service/api_service.dart';
import 'home_screen.dart';
import 'history_order/history_order.dart';
import 'setting_screen/screens/setting_screen.dart';

class Mainwrapper extends StatefulWidget {
  final String username;
  final int userId;
  final VoidCallback onLogout;

  const Mainwrapper({
    super.key,
    required this.username,
    required this.userId,
    required this.onLogout,
  });

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
    inventoryScreen = HistoryOrder(key: _inventoryKey, userId: widget.userId);
  }

  // *Fungsi untuk membangun daftar layar yang akan ditampilkan
  List<Widget> _buildScreens() {
    return [
      HomeScreen(username: widget.username, userId: widget.userId),
      inventoryScreen,
      SettingScreen(
        userId: widget.userId,
        onSyncSuccess: () {
          _inventoryKey.currentState?.refreshData();
        },
        username: widget.username,
      ),
      CustomerScreen(),
      StockScreen(),
    ];
  }

  // *Fungsi untuk mengonfirmasi logout
  Future<void> _confirmLogout() async {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      title: "Logout",
      desc: "Apakah anda yakin untuk Logout?",
      dialogType: DialogType.warning,
      width: 400,
      headerAnimationLoop: false,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF486471) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
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
            width: 120,
            color: const Color.fromRGBO(36, 70, 82, 1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _buildNavItem(
                  icon: Icons.history,
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _buildNavItem(
                  icon: FontAwesome.address_book_solid,
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _buildNavItem(
                  icon: FontAwesome.box_archive_solid,
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
