import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/view/history_order/history_order.dart';
import 'package:aplikasi_demo_test/view/login_screen.dart';
import 'package:aplikasi_demo_test/view/mobile_screen/home_page.dart';
import 'package:aplikasi_demo_test/view/mobile_screen/summary_page.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

class MobileWrapper extends StatefulWidget {
  const MobileWrapper({super.key});

  @override
  State<MobileWrapper> createState() => _MobileWrapperState();
}

class _MobileWrapperState extends State<MobileWrapper> {
  final api = ApiService();
  int _selectedIndex = 0;
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

  List<Widget> _buildScreens() {
    return [HomePage(), HistoryOrder(), SummaryPage()];
  }

  List<NavigationDestination> items() {
    return [
      NavigationDestination(icon: Icon(Icons.home), label: "Home"),
      NavigationDestination(icon: Icon(Icons.history), label: "History"),
      NavigationDestination(icon: Icon(Icons.book), label: "Laporan Keuangan"),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IndexedStack(index: _selectedIndex, children: _buildScreens()),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.logout),
          onPressed: () {
            _confirmLogout();
          },
        ),
        bottomNavigationBar: NavigationBar(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
            }

            return const TextStyle(
              fontSize: 11,
              overflow: TextOverflow.ellipsis,
            );
          }),

          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          selectedIndex: _selectedIndex,
          destinations: items(),
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: AppColor.backgroundColorSecondry,

          indicatorColor: AppColor.buttonColor.withOpacity(0.15),
        ),
      ),
    );
  }
}
