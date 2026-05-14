import 'package:aplikasi_demo_test/utils/responsive.dart';
import 'package:aplikasi_demo_test/view/main_wrapper.dart';
import 'package:aplikasi_demo_test/view/mobile_wrapper.dart';
import 'package:flutter/material.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isTablet(context)) {
      return SafeArea(child: Mainwrapper());
    }
    return MobileWrapper();
  }
}
