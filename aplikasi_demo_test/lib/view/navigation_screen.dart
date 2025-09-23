import 'dart:async';

import 'package:aplikasi_demo_test/view/main_wrapper.dart';
import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../service/api_service.dart';

class NavigationScreen extends StatefulWidget {
  final int userId;

  const NavigationScreen({super.key, required this.userId});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Map<String, dynamic>? userData;
  Timer? _timer;
  String? _errorMsg;
  final api = ApiService();
  @override
  void initState() {
    super.initState();
    _loadUserFromStorage();
  }

  // *Fungsi untuk memuat data user dari penyimpanan shared preferences
  Future<void> _loadUserFromStorage() async {
    try {
      final data = await AuthService.getUserData();
      if (data == null || data['id'] != widget.userId) {
        setState(() {
          _errorMsg = 'User tidak ditemukan.';
        });
        return;
      }

      setState(() {
        userData = data;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Gagal memuat user: $e';
      });
    }
  }

  // *Fungsi untuk logout dari aplikasi
  Future<void> _logout() async {
    try {
      await api.logout();
    } catch (e) {
      print('Gagal logout dari backend: $e');
    }

    await AuthService.logout();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _errorMsg!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Mainwrapper(
        username: userData!['username'],
        onLogout: _logout,
        userId: userData!['id'],
      ),
    );
  }
}
