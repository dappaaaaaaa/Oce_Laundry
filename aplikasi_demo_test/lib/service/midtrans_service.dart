import 'package:dio/dio.dart';

class MidtransService {
  static const String _backendBaseUrl = "https://qlaundry.web.id/";

  // *Iniliasi Dio untuk meminta request dengan backend
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _backendBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // * Fungsi untuk membuat transaksi dengan Midtrans
  static Future<String?> createTransaction(Map<String, dynamic> payload) async {
    try {
      final response = await dio.post(
        '/api/midtrans/snap-token',
        data: payload,
      );

      if (response.statusCode == 200) {
        return "https://app.midtrans.com/snap/v2/vtweb/${response.data['snap_token']}";
      } else {
        print("Backend Error: ${response.data}");
        return null;
      }
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.data ?? e.message}");
      return null;
    }
  }
}
