import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _userDataKey = 'user_data';

  // * Fungsi untuk menyimpan data user
  static Future<void> saveUserData({
    required String token,
    required int id,
    required String username,
    required String email,
  }) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_id', value: id.toString());

    final prefs = await SharedPreferences.getInstance();
    final userData = {'id': id, 'username': username, 'email': email};
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  // * Fungsi untuk mengambil data user
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // * Fungsi untuk menghapus data user
  static Future<void> logout() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // * Fungsi untuk mengecek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // * Fungsi untuk mendapatkan ID user
  static Future<int?> getUserId() async {
    final id = await _storage.read(key: 'user_id');
    return id != null ? int.tryParse(id) : null;
  }

  // * Fungsi untuk mendapatkan token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
