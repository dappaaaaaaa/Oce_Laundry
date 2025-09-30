import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aplikasi_demo_test/service/midtrans_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class MidtransPaymentScreen extends StatefulWidget {
  final int amount;
  final String customerName;
  final String customerPhone;

  const MidtransPaymentScreen({
    super.key,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  bool isLoading = true;
  String? paymentUrl;
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final url = request.url;

                print("📦 Navigating to: $url");

                if (url.contains('finish') ||
                    url.contains('order_id=') ||
                    url.contains('status_code=') ||
                    url.contains('transaction_status=settlement') ||
                    url.contains('finish.qris.callback')) {
                  Navigator.pop(context, true);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );

    _createTransaction();
  }

  // *Fungsi untuk membuat transaksi QRIS
  Future<void> _createTransaction() async {
    final payload = {
      "amount": widget.amount,
      "customer_name": widget.customerName,
      "customer_email": "${widget.customerPhone}@qris.test",
    };

    final url = await MidtransService.createTransaction(payload);
    if (url != null) {
      setState(() {
        paymentUrl = url;
        isLoading = false;
      });
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran QRIS"),
        backgroundColor: AppColor.backgroundColorPrimary,
      ),
      body:
          isLoading
              ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: AppColor.primary,
                  size: 40,
                ),
              )
              : WebViewWidget(controller: _controller),
    );
  }
}
