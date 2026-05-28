import 'dart:io';

import 'package:aplikasi_demo_test/database/order.dart';
import 'package:aplikasi_demo_test/utils/variable.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_demo_test/database/user.dart';
import 'auth_service.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';

class ApiService {
  final Dio dio;
  late String message;
  static final String baseUrl = Variable.baseUrl;
  ApiService()
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          final code = e.response?.statusCode;
          if (code == 400) {
            message = "Gagal Memasukan Data";
          } else if (code == 500) {
            message = "Gagal Menyimpan data";
          } else if (e.type == DioExceptionType.connectionTimeout) {
            message =
                "Tidak ada respon dari server, Timeout Lebih dari 15 detik. server kemungkinan tidak aktif";
          } else {
            message = e.message ?? "Terjadi Kesalahan yang tidak Diketahui";
          }
          return handler.next(e);
        },
      ),
    );
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
    dio.interceptors.add(HttpFormatter());
  }

  Future<List<dynamic>> getStocks() async {
    try {
      final response = await dio.get("$baseUrl/stock/");

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      return [];
    } catch (e) {
      throw Exception("Gagal mengambil data: $e");
    }
  }

  Future<bool> createStock({
    required String nama,
    required int kuantitas,
    required String unit,
    String? keterangan,
    File? image,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "nama": nama,
        "kuantitas": kuantitas,
        "unit": unit,
        "keterangan": keterangan,
        if (image != null)
          "image": await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
      });

      final response = await dio.post("$baseUrl/stock/", data: formData);

      return response.statusCode == 201;
    } catch (e) {
      throw Exception("Gagal menambahkan data: $e");
    }
  }

  Future<bool> updateStock({
    required int id,
    required String nama,
    required int kuantitas,
    required String unit,
    String? keterangan,
    File? image,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "nama": nama,
        "kuantitas": kuantitas,
        "keterangan": keterangan,
        "unit": unit,
        if (image != null)
          "image": await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
      });

      final response = await dio.post(
        "$baseUrl/stock/update/$id",
        data: formData,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Gagal update data: $e");
    }
  }

  Future<bool> deleteStock(int id) async {
    try {
      final response = await dio.delete("$baseUrl/stock/$id");

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Gagal menghapus data: $e");
    }
  }

  // *Fungsi untuk login
  Future<User?> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      final body = response.data;

      if (body['status'] == true) {
        final data = body['user'];
        final token = body['token'];
        print('Login berhasil: ${body['message']}');
        print('Token: $token');

        return User(
          id: data['id'],
          email: data['email'],
          username: data['name'],
          password: '',
          token: token,
        );
      } else {
        print('Login gagal: ${body['message']}');
      }
    } on DioException catch (e) {
      print('Login error: ${e.response?.data ?? e.message}');
    }

    return null;
  }

  // *Fungsi untuk logout
  Future<void> logout() async {
    final token = await AuthService.getToken();
    try {
      final response = await dio.post(
        '/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Logout API status: ${response.statusCode}');
    } on DioException catch (e) {
      print('Logout error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  // *Fungsi untuk mengambil daftar produk
  Future<List<dynamic>> fetchProductList() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    try {
      final response = await dio.get(
        '/barang',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data;
      if (body['status'] == true && body['data'] != null) {
        return body['data'];
      } else {
        throw Exception('Data kosong atau tidak ditemukan');
      }
    } on DioException catch (e) {
      throw Exception(
        'Gagal memuat data: ${e.response?.statusCode} - ${e.message}',
      );
    }
  }

  // *Fungsi untuk mengambil token dari SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // *Fungsi untuk mengirim data order berdasarkan user ID
  Future<int?> postOrder(Map<String, dynamic> order, String? token) async {
    try {
      final response = await dio.post(
        '/orders',
        data: order,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['id'];
    } on DioException catch (e) {
      print('postOrder gagal: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  // *Fungsi untuk mengirim data order item
  Future<bool> postOrderItem(Map<String, dynamic> item, String? token) async {
    try {
      final response = await dio.post(
        '/orderItem',
        data: item,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('postOrderItem gagal: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  // *Fungsi untuk request reset password
  Future<Map<String, dynamic>> requestResetPassword(String email) async {
    try {
      final response = await dio.post(
        '/password-reset/request',
        data: {"email": email},
        options: Options(headers: {"Accept": "application/json"}),
      );
      return response.data;
    } on DioException catch (e) {
      // Ambil data JSON dari response walaupun status code 404 atau 409
      if (e.response != null) {
        print("Request error: ${e.response?.data}");
        return e.response!.data;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> checkStatus(String email) async {
    try {
      final response = await dio.get(
        "/password-reset/status",
        queryParameters: {"email": email},
        options: Options(
          headers: {"Accept": "application/json"},
          contentType: 'application/json',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print("checkStatus error: ${e.response!.data}");
        return e.response!.data;
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await dio.post(
        "/password-reset/change",
        data: {"email": email, "password": newPassword},
        options: Options(
          headers: {"Accept": "application/json"},
          contentType: 'application/json',
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print("changePassword error: ${e.response!.data}");
        return e.response!.data;
      } else {
        rethrow;
      }
    }
  }

  Future<List<Order>> getOrders(String? token) async {
    try {
      final response = await dio.get(
        '/orders',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final List data = response.data['data'];

      return data.map((e) => Order.fromMap(e)).toList();
    } on DioException catch (e) {
      print(e.response?.data);

      return [];
    }
  }

  Future<bool> updateOrderStatus(
    int orderId,
    int newStatus,
    String? token,
  ) async {
    try {
      final response = await dio.put(
        '/orders/$orderId/status',
        data: {'is_order_complete': newStatus},
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getOrderItemDetailsWithProduct(
    int orderId,
    String? token,
  ) async {
    try {
      final response = await dio.get(
        '/orders/$orderId/items',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final List data = response.data['data'];

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException {
      return [];
    }
  }

  Future<Order?> getOrderById(int id, String? token) async {
    try {
      final response = await dio.get(
        '/orders/$id',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return Order.fromMap(response.data['data']);
    } on DioException {
      return null;
    }
  }

  Future<Map<int, int>> getJumlahOrderPerStatus(String? token) async {
    try {
      final response = await dio.get(
        '/orders/count/status',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final List<dynamic> data = response.data['data'];

      final Map<int, int> result = {};

      for (int i = 0; i < data.length; i++) {
        result[i] = data[i] as int;
      }

      return result;
    } on DioException {
      return {};
    }
  }

  Future<bool> deleteOrderItem(int id, String? token) async {
    try {
      await dio.delete(
        '/order-items/$id',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return true;
    } on DioException catch (e) {
      print(e.response?.data);
      return false;
    }
  }

  Future<bool> deleteOrder(int id, String? token) async {
    try {
      await dio.delete(
        '/orders/$id',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return true;
    } on DioException catch (e) {
      print(e.response?.data);
      return false;
    }
  }

  Future<bool> updateOrderPayment(
    int orderId,
    int paymentAmount,
    int isComplete,
    int paymentMethod,
    String token,
  ) async {
    try {
      final response = await dio.put(
        '$baseUrl/orders/$orderId/payment',
        data: {
          'total_payment': paymentAmount,
          'is_payment_complete': isComplete,
          'payment_method': paymentMethod,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
