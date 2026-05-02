// ignore_for_file: use_build_context_synchronously

import 'package:aplikasi_demo_test/utils/widget.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/print_struk.dart';
import 'package:aplikasi_demo_test/utils/message_string.dart';
import 'package:aplikasi_demo_test/view/history_order/report_status_widget.dart';
import 'package:aplikasi_demo_test/view/update_payment_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/database_helper.dart';

class HistoryOrder extends StatefulWidget {
  final int userId;

  const HistoryOrder({super.key, required this.userId});

  @override
  HistoryOrderState createState() => HistoryOrderState();
}

class HistoryOrderState extends State<HistoryOrder>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _futureOrders;
  int jumlahOrder = 0;
  Map<int, int> jumlahOrderPerStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadJumlahOrderPerStatus();
    DatabaseHelper().getJumlahOrderStatusid(0).then((value) {
      setState(() {
        jumlahOrder = value;
      });
    });
  }

  Future<void> showPrintingDialog({
    required BuildContext context,
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> items,
  }) async {
    bool isSecondPrint = false;
    bool isFinished = false;
    bool isSkipped = false;

    late StateSetter dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            return AlertDialog(
              backgroundColor: AppColor.backgroundColorPrimary,
              title: Text(
                isSecondPrint ? "Mencetak Struk Kedua" : "Mencetak Struk",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: AppColor.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSecondPrint
                        ? "Sedang mencetak struk kedua..."
                        : "Sedang mencetak struk pertama...",
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isSecondPrint)
                        ElevatedButton(
                          onPressed: () {
                            isSkipped = true;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(120, 50),
                          ),
                          child: const Text("Lewati Cetak Kedua"),
                        ),
                      ElevatedButton(
                        onPressed: () async {
                          if (!isSecondPrint) {
                            dialogSetState(() {
                              isSecondPrint = true;
                            });
                            await cetakStrukLaundryEscPos(
                              order: order,
                              items: items,
                            );
                            await Future.delayed(const Duration(seconds: 10));
                            if (context.mounted) Navigator.pop(context);
                          } else if (!isFinished) {
                            isFinished = true;
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(140, 50),
                        ),
                        child: Text(
                          isSecondPrint
                              ? "Selesai"
                              : "Cetak Struk Kedua Sekarang",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    await cetakStrukLaundryEscPos(order: order, items: items);

    await Future.delayed(const Duration(seconds: 10));

    if (!isSecondPrint && !isSkipped && context.mounted) {
      dialogSetState(() {
        isSecondPrint = true;
      });

      await cetakStrukLaundryEscPos(order: order, items: items);
      await Future.delayed(const Duration(seconds: 10));

      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadJumlahOrderPerStatus() async {
    final Map<int, int> statusCounts = {};

    for (int status = 0; status <= 3; status++) {
      final count = await DatabaseHelper().getJumlahOrderStatusid(status);
      statusCounts[status] = count;
    }

    setState(() {
      jumlahOrderPerStatus = statusCounts;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _futureOrders = DatabaseHelper().getUnsyncedOrders().then(
        (data) => data.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
      _loadJumlahOrderPerStatus();
    });
  }

  String generateOrderNumber(DateTime transactionDate, int orderId) {
    final datePart =
        '${transactionDate.year.toString().substring(2)}${transactionDate.day.toString().padLeft(2, '0')}${transactionDate.month.toString().padLeft(2, '0')}';
    final idPart = orderId.toString().padLeft(3, '0');
    return '$datePart$idPart';
  }

  String formatNumber(num value) {
    return NumberFormat.decimalPattern('id_ID').format(value);
  }

  Future<void> deleteOrderDialog(BuildContext context, int orderId) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      width: 400,
      title: "Konfirmasi Hapus",
      desc:
          "Apakah Anda yakin ingin menghapus pesanan ini? Tindakan ini tidak dapat dibatalkan.",
      btnCancelText: "Batal",
      btnOkText: "Hapus",
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final db = DatabaseHelper();
        await db.deleteOrderItemsByOrderId(orderId);
        await db.deleteOrder(orderId);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pesanan berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      },
    ).show();
  }

  String getPaymentMethodLabel(String value) {
    switch (value) {
      case '0':
        return "Cash";
      case '1':
        return "QRIS";
      case '2':
        return "Bayar Nanti";
      default:
        return "Tidak diketahui";
    }
  }

  Future<void> showOrderDetailDialog(
    BuildContext context,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    final metodePembayaran = () {
      switch (order['payment_method'].toString()) {
        case '0':
          return 'Cash';
        case '1':
          return 'QRIS';
        case '2':
          return 'Belum Bayar';
        default:
          return 'Tidak diketahui';
      }
    }();

    final total = order['total'] ?? 0;
    final bayar = order['total_payment'] ?? 0;
    final kembalian = bayar - total;
    final transactionDate = DateTime.fromMillisecondsSinceEpoch(
      order['transaction_time'],
    );
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: 500,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      btnOkText: "Tutup",
      btnOkOnPress: () {},
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pemesanan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text('ID Transaksi: ${order['id']}'),
                Text(
                  'Nomor Pemesanan: ${generateOrderNumber(transactionDate, order['id'])}',
                ),
                Text('Tanggal: ${formatTime(order['transaction_time'])}'),
                const Divider(thickness: 1, height: 24),
                Text('Nama Pelanggan: ${order['customer_name']}'),
                Text('Nomor HP: 0${order['phone_number']}'),
                Text('Nama Kasir: ${order['cashier_name']}'),
                Text('Metode Pembayaran: $metodePembayaran'),
                const Divider(thickness: 1, height: 24),
                Text('Total Item: ${order['total_item']}'),
                Text('Subtotal: ${formatCurrency(order['sub_total'])}'),
                Text('Total: ${formatCurrency(order['total'])}'),
                Text('Bayar: ${formatCurrency(order['total_payment'])}'),
                Text('Kembalian: ${formatCurrency(kembalian)}'),
                const Divider(thickness: 1, height: 24),
                Text(
                  'Daftar Produk:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...items.map((item) {
                  final total = (item['weight'] ?? 0) * (item['price'] ?? 0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['product_name']}',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['weight']} x ${formatCurrency(item['price'])}',
                            ),
                            Text(formatCurrency(total)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    ).show();
  }

  String formatted = DateFormat('EEEE, d MMMM', 'id_ID').format(DateTime.now());

  String formatCurrency(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String formatTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  Future<void> refreshData() async {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColor.backgroundColorPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Riwayat Penjualan", style: TextStyle(fontSize: 24)),
              Text(
                formatted,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusOrderWidget(
                    label: "Antrian",
                    status: 0,
                    color: Colors.orange,
                    jumlah: jumlahOrderPerStatus[0] ?? 0,
                  ),
                  StatusOrderWidget(
                    label: " Proses",
                    status: 1,
                    color: Colors.blue,
                    jumlah: jumlahOrderPerStatus[1] ?? 0,
                  ),
                  StatusOrderWidget(
                    label: "Siap Diambil",
                    status: 2,
                    color: Colors.purple,
                    jumlah: jumlahOrderPerStatus[2] ?? 0,
                  ),
                  StatusOrderWidget(
                    label: "Selesai",
                    status: 3,
                    color: Colors.green,
                    jumlah: jumlahOrderPerStatus[3] ?? 0,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refreshData,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureOrders,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Tidak ada data transaksi.'),
                        );
                      }

                      final orders = snapshot.data!;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 20),
                                Card(
                                  clipBehavior: Clip.antiAlias,
                                  color: AppColor.backgroundColorPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: DataTable(
                                        dataRowMaxHeight: 60,
                                        dataRowMinHeight: 30,
                                        columnSpacing: 43,
                                        headingRowColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) => AppColor.primary,
                                            ),
                                        headingTextStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: TableBorder.all(
                                          color: Colors.black,
                                          width: 0.5,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                        columns: const [
                                          DataColumn(label: Text('No')),
                                          DataColumn(label: Text('Customer')),
                                          DataColumn(label: Text('Nomor HP')),
                                          DataColumn(
                                            label: Text('Tanggal & Waktu'),
                                          ),
                                          DataColumn(
                                            label: Text('Status Pesanan'),
                                          ),
                                          DataColumn(label: Text('Aksi')),
                                        ],
                                        rows:
                                            orders.asMap().entries.map((entry) {
                                              final index = entry.key;
                                              final order = entry.value;

                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Text("${index + 1}"),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      order['customer_name'],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      "0${order['phone_number'].toString()}",
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Column(
                                                      children: [
                                                        Gap(5),
                                                        Text(
                                                          formatTime(
                                                            order['transaction_time'],
                                                          ),
                                                        ),
                                                        Gap(5),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                order['transaction_complete_time'] !=
                                                                        null
                                                                    ? Colors
                                                                        .green
                                                                        .withOpacity(
                                                                          0.1,
                                                                        )
                                                                    : Colors
                                                                        .orange
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            order['transaction_complete_time'] !=
                                                                    null
                                                                ? "Selesai • ${formatTime(order['transaction_complete_time'])}"
                                                                : "Diproses",
                                                            style: TextStyle(
                                                              color:
                                                                  order['transaction_complete_time'] !=
                                                                          null
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .orange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(
                                                    order['is_order_complete'] ==
                                                            3
                                                        ? orderStatusRow(
                                                          icon:
                                                              Icons
                                                                  .check_circle,
                                                          color: Colors.green,
                                                          text: "Selesai",
                                                        )
                                                        : Theme(
                                                          data: ThemeData(
                                                            canvasColor:
                                                                AppColor
                                                                    .backgroundColorPrimary,
                                                          ),
                                                          child: DropdownButton<
                                                            String
                                                          >(
                                                            isExpanded: true,
                                                            value:
                                                                order['is_order_complete']
                                                                    .toString(),
                                                            items: [
                                                              DropdownMenuItem(
                                                                value: '0',
                                                                child: orderStatusRow(
                                                                  icon:
                                                                      FontAwesome
                                                                          .clock_solid,
                                                                  color:
                                                                      Colors
                                                                          .orange,
                                                                  text:
                                                                      "Antrian",
                                                                ),
                                                              ),
                                                              DropdownMenuItem(
                                                                value: '1',
                                                                child: orderStatusRow(
                                                                  icon:
                                                                      Icons
                                                                          .work,
                                                                  color:
                                                                      Colors
                                                                          .blue,
                                                                  text:
                                                                      "Proses",
                                                                ),
                                                              ),
                                                              DropdownMenuItem(
                                                                value: '2',
                                                                child: orderStatusRow(
                                                                  icon:
                                                                      Icons
                                                                          .shopping_bag,
                                                                  color:
                                                                      Colors
                                                                          .purple,
                                                                  text:
                                                                      "Siap Diambil",
                                                                ),
                                                              ),
                                                              DropdownMenuItem(
                                                                value: '3',
                                                                child: orderStatusRow(
                                                                  icon:
                                                                      Icons
                                                                          .check_circle,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                  text:
                                                                      "Selesai",
                                                                ),
                                                              ),
                                                            ],
                                                            onChanged: (
                                                              newValue,
                                                            ) {
                                                              AwesomeDialog(
                                                                context:
                                                                    context,
                                                                width: 400,
                                                                dialogBackgroundColor:
                                                                    AppColor
                                                                        .backgroundColorPrimary,
                                                                headerAnimationLoop:
                                                                    false,
                                                                dismissOnBackKeyPress:
                                                                    false,
                                                                dismissOnTouchOutside:
                                                                    false,
                                                                keyboardAware:
                                                                    true,
                                                                dialogType:
                                                                    DialogType
                                                                        .noHeader,
                                                                btnCancelText:
                                                                    "Tidak",
                                                                btnOkText:
                                                                    "Iya",
                                                                title:
                                                                    "Pemberitahuan",
                                                                desc:
                                                                    "Apakah anda yakin ingin melakukan perubahan status pemesanan?",
                                                                btnOkOnPress: () async {
                                                                  await DatabaseHelper().updateOrderStatus(
                                                                    order['id'],
                                                                    int.parse(
                                                                      newValue!,
                                                                    ),
                                                                  );
                                                                  _loadData();
                                                                },
                                                                btnCancelOnPress:
                                                                    () {},
                                                              ).show();
                                                            },
                                                          ),
                                                        ),
                                                  ),

                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () async {
                                                            final db =
                                                                DatabaseHelper();
                                                            final items = await db
                                                                .getOrderItemDetailsWithProduct(
                                                                  order['id'],
                                                                );
                                                            final isConnected =
                                                                await PrintBluetoothThermal
                                                                    .connectionStatus;

                                                            if (!isConnected) {
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Printer belum terhubung. Sambungkan terlebih dahulu.',
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                );
                                                              }
                                                              return;
                                                            }

                                                            await showPrintingDialog(
                                                              context: context,
                                                              order: order,
                                                              items: items,
                                                            );
                                                          },

                                                          icon: Icon(
                                                            Icons.print,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            final phoneNumber =
                                                                order['phone_number']
                                                                    .toString();
                                                            final statusMap = {
                                                              '0':
                                                                  'Sedang dalam antrian',
                                                              '1':
                                                                  'Sedang diproses',
                                                              '2':
                                                                  'Siap diambil',
                                                              '3':
                                                                  'Sudah selesai',
                                                            };
                                                            final status =
                                                                statusMap[order['is_order_complete']
                                                                    .toString()] ??
                                                                'Belum diketahui';
                                                            final db =
                                                                DatabaseHelper();
                                                            final items = await db
                                                                .getOrderItemDetailsWithProduct(
                                                                  order['id'],
                                                                );
                                                            final message =
                                                                generateOrderMessageText(
                                                                  order: order,
                                                                  items: items,
                                                                  status:
                                                                      status,
                                                                );

                                                            final whatsappUrl =
                                                                Uri.parse(
                                                                  'https://wa.me/62$phoneNumber?text=${Uri.encodeComponent(message)}',
                                                                );
                                                            if (await canLaunchUrl(
                                                              whatsappUrl,
                                                            )) {
                                                              await launchUrl(
                                                                whatsappUrl,
                                                                mode:
                                                                    LaunchMode
                                                                        .externalApplication,
                                                              );
                                                            } else {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Gagal membuka WhatsApp',
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          icon: Icon(
                                                            FontAwesome
                                                                .whatsapp_brand,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.info_outline,
                                                            color: Colors.blue,
                                                          ),
                                                          onPressed: () async {
                                                            final db =
                                                                DatabaseHelper();
                                                            final items = await db
                                                                .getOrderItemDetailsWithProduct(
                                                                  order['id'],
                                                                );
                                                            showOrderDetailDialog(
                                                              context,
                                                              order,
                                                              items,
                                                            );
                                                          },
                                                        ),
                                                        if (order['is_payment_complete']
                                                                .toString() ==
                                                            '0')
                                                          IconButton(
                                                            onPressed: () async {
                                                              if (order['is_payment_complete'] ==
                                                                  0) {
                                                                final result = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => UpdatePaymentScreen(
                                                                          orderData:
                                                                              order,
                                                                        ),
                                                                  ),
                                                                );
                                                                if (result ==
                                                                    true) {
                                                                  _loadData();
                                                                  setState(
                                                                    () {},
                                                                  );
                                                                }
                                                              }
                                                            },
                                                            icon: Icon(
                                                              Icons
                                                                  .payment_rounded,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        if (order['is_order_complete'] !=
                                                            3)
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.delete,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed: () async {
                                                              deleteOrderDialog(
                                                                context,
                                                                order['id'],
                                                              );
                                                            },
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
