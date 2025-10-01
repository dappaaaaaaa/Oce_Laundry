import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/view/setting_screen/screens/setting_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:choice/choice.dart';
import '../../../database/product.dart';
import '../../../database/database_helper.dart';
import '../../../service/auth_service.dart';

class SettingScreen extends StatefulWidget {
  final int userId;
  final String username;
  final VoidCallback onSyncSuccess;

  const SettingScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.onSyncSuccess,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isSyncing = false;
  bool isLoading = false;
  List<String> choices = [
    'Kelola Printer',
    'Kelola Pajak & Diskon',
    'Sinkroniasi',
  ];
  List<Icon> icon = [
    Icon(Icons.print_rounded),
    Icon(Icons.attach_money_rounded),
    Icon(Icons.compare_arrows_rounded),
  ];
  String? selectedValue;
  bool isFormVisible = false;
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  int totalItems = 0;
  int currentItem = 0;

  @override
  void initState() {
    super.initState();
    selectedValue = choices.first;
  }

  @override
  void dispose() {
    super.dispose();
    amountController.dispose();
    nameController.dispose();
  }

  // * Fungsi untuk mengatur nilai yang dipilih
  Future<void> setSelectedValue(String? value) async {
    setState(() => selectedValue = value);
  }

  // * Fungsi untuk menyinkronkan transaksi
  Future<void> _syncTransaksi(BuildContext context) async {
    if (_isSyncing) return;
    _isSyncing = true;
    setState(() {
      isLoading = true;
      currentItem = 0;
      totalItems = 0;
    });

    final db = DatabaseHelper();
    final unsyncedOrders = await db.getUnsyncedOrdersReady();

    if (unsyncedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada transaksi yang perlu disinkronkan"),
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Token tidak ditemukan. Silakan login ulang."),
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    totalItems = unsyncedOrders.length;

    for (final order in unsyncedOrders) {
      final localOrderId = order['id'];
      final items = await db.getOrderItemsByOrderId(localOrderId);
      final originalTransactionTime = DateTime.fromMillisecondsSinceEpoch(
        order['transaction_time'],
      );
      final formattedTime = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(originalTransactionTime);

      final orderPayload = {
        'total_payment': order['total_payment'],
        'sub_total': order['sub_total'],
        'tax': order['tax'],
        'discount': order['discount'],
        'total': order['total'],
        'total_item': order['total_item'],
        'payment_method': order['payment_method'],
        'transaction_time': formattedTime,
        'customer_name': order['customer_name'],
        'phone_number': order['phone_number'].toString(),
        'cashier_name': order['cashier_name'],
      };

      try {
        final orderId = await ApiService().postOrder(orderPayload, token);
        if (orderId == null)
          throw Exception("Gagal mendapatkan ID order dari server");

        for (final item in items) {
          final itemPayload =
              Map.of(item)
                ..remove('id')
                ..remove('product_id')
                ..['order_id'] = orderId
                ..['products_id'] = item['product_id'];

          final itemSuccess = await ApiService().postOrderItem(
            itemPayload,
            token,
          );
          if (!itemSuccess) throw Exception("Gagal mengirim order item");
        }

        await db.deleteOrder(localOrderId);
        await db.deleteOrderItemsByOrderId(localOrderId);
      } catch (e) {
        print('Gagal sinkronisasi order $localOrderId: $e');
      }

      setState(() {
        currentItem++;
      });
    }

    widget.onSyncSuccess();
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sinkronisasi transaksi selesai')),
    );
  }

  // * Fungsi untuk menyinkronkan produk
  Future<void> _syncProduct(BuildContext context) async {
    setState(() => isLoading = true);
    try {
      final productApi = await ApiService().fetchProductList();
      if (productApi.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data Produk untuk disinkronkan'),
          ),
        );
        return;
      }

      final db = await DatabaseHelper().database;

      List<int> backendProductIds = [];

      for (var productMap in productApi) {
        final product = Product.fromJson(productMap);
        backendProductIds.add(product.id);
        await DatabaseHelper().insertProducts(product);
      }

      final localProducts = await db.query('products', columns: ['id']);
      final localProductIds =
          localProducts.map((row) => row['id'] as int).toList();

      final idsToDelete =
          localProductIds
              .where((id) => !backendProductIds.contains(id))
              .toList();

      for (var id in idsToDelete) {
        await db.delete('products', where: 'id = ?', whereArgs: [id]);
      }

      widget.onSyncSuccess();
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sinkronisasi berhasil!')));
    } catch (e) {
      setState(() => isLoading = false);
      print('Sync Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sinkronisasi gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColor.backgroundColorPrimary,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    height: 700,
                    child: Choice<String>.inline(
                      clearable: false,
                      value: ChoiceSingle.value(selectedValue),
                      onChanged: ChoiceSingle.onChanged(setSelectedValue),
                      itemCount: choices.length,
                      itemBuilder: (state, index) {
                        return SizedBox(
                          width: double.infinity,
                          height: 100,
                          child: ChoiceChip(
                            labelPadding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap, // Reduces extra space
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              side: BorderSide.none,
                            ),
                            visualDensity: VisualDensity(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            elevation: 1,
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                    choices[index],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  icon[index],
                                ],
                              ),
                            ),
                            selected: state.selected(choices[index]),
                            onSelected: state.onSelected(choices[index]),
                            showCheckmark: false,
                            selectedShadowColor: Colors.black,
                            selectedColor: const Color(0xFFEBEAEA),
                            backgroundColor: AppColor.backgroundColorPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                  VerticalDivider(),
                  Expanded(
                    child: SettingContentWidget(
                      selectedValue: selectedValue,
                      username: widget.username,
                      onSyncProduct: () => _syncProduct(context),
                      onSyncTransaksi: () => _syncTransaksi(context),
                      onSyncSuccess: widget.onSyncSuccess,
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: AppColor.backgroundColorPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    height: 160,
                    width: 220,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LoadingAnimationWidget.staggeredDotsWave(
                            color: AppColor.primary,
                            size: 40,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Menyinkronkan...",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (totalItems > 0)
                            Text(
                              "$currentItem dari $totalItems item",
                              style: TextStyle(color: Colors.black),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
