// ignore_for_file: use_build_context_synchronously

import 'package:aplikasi_demo_test/database/order.dart';
import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/service/auth_service.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:aplikasi_demo_test/utils/widget.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/print_struk.dart';
import 'package:aplikasi_demo_test/utils/message_string.dart';
import 'package:aplikasi_demo_test/view/history_order/report_status_widget.dart';
import 'package:aplikasi_demo_test/view/update_payment_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:page_transition/page_transition.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class HistoryOrder extends StatefulWidget {
  const HistoryOrder({super.key});

  @override
  HistoryOrderState createState() => HistoryOrderState();
}

class HistoryOrderState extends State<HistoryOrder>
    with AutomaticKeepAliveClientMixin {
  Future<List<Order>>? _futureOrders;
  int jumlahOrder = 0;
  final searchController = SearchController();
  bool _isLoading = false;
  Map<int, int> jumlahOrderPerStatus = {};
  List<dynamic> filteredList = [];
  List<Order> allOrders = [];
  String searchQuery = '';

  int? selectedStatus;

  DateTimeRange? selectedDateRange;
  final token = AuthService.getToken();
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> showPrintingDialog({
    required BuildContext context,
    required Order order,
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
                style: TextStyle(fontSize: 30.sp),
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
                    style: TextStyle(fontSize: 30.sp),
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
                      Gap(10),
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
    final tokenValue = await token;

    final result = await ApiService().getJumlahOrderPerStatus(tokenValue);

    setState(() {
      jumlahOrderPerStatus = result;
    });
  }

  Future<void> _loadData() async {
    final tokenValue = await token;

    setState(() {
      _futureOrders = ApiService().getOrders(tokenValue);
    });

    final orders = await ApiService().getOrders(tokenValue);

    setState(() {
      allOrders = orders;
      filteredList = orders;
    });

    await _loadJumlahOrderPerStatus();
  }

  String generateOrderNumber(DateTime transactionDate, int orderId) {
    final datePart =
        '${transactionDate.year.toString().substring(2)}'
        '${transactionDate.month.toString().padLeft(2, '0')}'
        '${transactionDate.day.toString().padLeft(2, '0')}';

    final idPart = orderId.toString().padLeft(3, '0');

    return '$datePart$idPart';
  }

  String formatNumber(num value) {
    return NumberFormat.decimalPattern('id_ID').format(value);
  }

  Future<void> deleteOrderDialog(BuildContext context, int orderId) async {
    AwesomeDialog(
      descTextStyle: TextStyle(fontSize: 30.sp),
      titleTextStyle: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w600),
      buttonsTextStyle: TextStyle(
        fontSize: 30.sp,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      headerAnimationLoop: false,
      width: 450,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      title: "Konfirmasi Hapus",
      desc:
          "Apakah Anda yakin ingin menghapus pesanan ini?\nTindakan ini tidak dapat dibatalkan.",
      btnCancelText: "Batal",
      btnOkText: "Hapus",
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        // LOADING
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              backgroundColor: AppColor.backgroundColorPrimary,
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  const Expanded(child: Text("Sedang menghapus pesanan...")),
                ],
              ),
            );
          },
        );
        try {
          final api = ApiService();
          final tokenValue = await token;
          final deleteItems = await api.deleteOrderItem(orderId, tokenValue);
          final deleteOrder = await api.deleteOrder(orderId, tokenValue);
          // tutup loading
          if (context.mounted) {
            Navigator.pop(context);
          }
          if (deleteItems && deleteOrder) {
            await _loadData();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan berhasil dihapus'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menghapus pesanan'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          // tutup loading
          if (context.mounted) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    Order order,
    List<Map<String, dynamic>> items,
  ) async {
    final metodePembayaran = () {
      switch (order.paymentMethod.toString()) {
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

    final total = order.total;
    final bayar = order.totalPayment;
    final kembalian = bayar - total;
    formatTime(order.transactionTime);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: 450,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      btnOkText: "Tutup",
      btnOkOnPress: () {},
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pemesanan',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID Transaksi: ${order.id}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Nomor Pemesanan: ${generateOrderNumber(DateTime.parse(order.transactionTime.toString()), order.id)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Tanggal: ${formatTime(order.transactionTime)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                const Divider(thickness: 1, height: 24),
                Text(
                  'Nama Pelanggan: ${order.customerName}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Nomor HP: ${order.phoneNumber ?? ""}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Nama Kasir: ${order.cashierName}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Metode Pembayaran: $metodePembayaran',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                const Divider(thickness: 1, height: 24),
                Text(
                  'Total Item: ${order.totalItem}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Subtotal: ${formatCurrency(order.subTotal)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Total: ${formatCurrency(order.total)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Bayar: ${formatCurrency(order.totalPayment)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                Text(
                  'Kembalian: ${formatCurrency(kembalian)}',
                  style: TextStyle(fontSize: 30.sp, color: Colors.black),
                ),
                const Divider(thickness: 1, height: 24),
                Text(
                  'Daftar Produk:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.sp,
                    color: Colors.black,
                  ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 30.sp,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['weight']} x ${formatCurrency(item['price'])}',
                              style: TextStyle(
                                fontSize: 30.sp,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              formatCurrency(total),
                              style: TextStyle(
                                fontSize: 30.sp,
                                color: Colors.black,
                              ),
                            ),
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

  String formatTime(String datetime) {
    final date = DateTime.parse(datetime);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<void> refreshData() async {
    _loadData();
  }

  void filterOrders() {
    List<Order> result = allOrders;

    // ================= SEARCH =================
    if (searchQuery.isNotEmpty) {
      result =
          result.where((item) {
            final nama = item.customerName.toLowerCase();

            final id = item.id.toString();

            return nama.contains(searchQuery.toLowerCase()) ||
                id.contains(searchQuery);
          }).toList();
    }

    // ================= STATUS =================
    if (selectedStatus != null) {
      result =
          result.where((item) {
            return item.isOrderComplete == selectedStatus;
          }).toList();
    }

    // ================= TANGGAL =================
    if (selectedDateRange != null) {
      result =
          result.where((item) {
            final date = DateTime.parse(item.transactionTime.toString());

            return date.isAfter(
                  selectedDateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(
                  selectedDateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
    }

    setState(() {
      filteredList = result;
    });
  }

  Future<void> showDateFilterDialog(BuildContext context) async {
    PickerDateRange? tempRange;
    int? tempStatus = selectedStatus;

    if (selectedDateRange != null) {
      tempRange = PickerDateRange(
        selectedDateRange!.start,
        selectedDateRange!.end,
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              actionsPadding: EdgeInsets.symmetric(vertical: 20),
              actionsOverflowButtonSpacing: 2,
              backgroundColor: AppColor.backgroundColorPrimary,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: Text(
                "Filter Transaksi",
                style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.bold),
              ),

              content: SizedBox(
                width: 800.w,
                height: 1200.h,

                child: Column(
                  children: [
                    SizedBox(
                      height: 80.h,
                      child: DropdownButtonFormField<int?>(
                        value: tempStatus,

                        dropdownColor: AppColor.backgroundColorPrimary,
                        style: TextStyle(fontSize: 30.sp, color: Colors.black),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(fontSize: 26.sp),
                          labelText: "Status Pesanan",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Semua"),
                          ),

                          DropdownMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.solidClock,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Text("Antrian"),
                              ],
                            ),
                          ),

                          DropdownMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(Icons.work, color: Colors.blue, size: 18),
                                const SizedBox(width: 10),
                                const Text("Proses"),
                              ],
                            ),
                          ),

                          DropdownMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  color: Colors.purple,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Text("Siap Diambil"),
                              ],
                            ),
                          ),

                          DropdownMenuItem(
                            value: 3,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                const Text("Selesai"),
                              ],
                            ),
                          ),
                        ],

                        onChanged: (value) {
                          setDialogState(() {
                            tempStatus = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 340.h,
                      child: SfDateRangePicker(
                        startRangeSelectionColor: AppColor.primary,
                        endRangeSelectionColor: AppColor.primary,
                        todayHighlightColor: AppColor.primary,
                        viewSpacing: 20,
                        selectionColor: AppColor.primary,
                        showActionButtons: false,
                        view: DateRangePickerView.month,
                        selectionShape: DateRangePickerSelectionShape.rectangle,
                        headerStyle: DateRangePickerHeaderStyle(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 26.sp,
                          ),
                          backgroundColor: AppColor.primary,
                          textAlign: TextAlign.center,
                        ),
                        monthViewSettings:
                            const DateRangePickerMonthViewSettings(
                              firstDayOfWeek: 1,
                            ),
                        selectionMode: DateRangePickerSelectionMode.range,
                        backgroundColor: AppColor.backgroundColorPrimary,
                        initialSelectedRange: tempRange,
                        onSelectionChanged: (args) {
                          setDialogState(() {
                            tempRange = args.value;
                          });
                        },
                      ),
                    ),

                    if (tempRange != null)
                      SizedBox(
                        height: 30,
                        child: Text(
                          "${tempRange!.startDate?.day}/${tempRange!.startDate?.month}/${tempRange!.startDate?.year}"
                          " - "
                          "${tempRange!.endDate?.day}/${tempRange!.endDate?.month}/${tempRange!.endDate?.year}",
                        ),
                      ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Batal",
                    style: TextStyle(fontSize: 30.sp, color: AppColor.primary),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      selectedStatus = null;
                      selectedDateRange = null;
                    });

                    filterOrders();

                    Navigator.pop(context);
                  },
                  child: Text(
                    "Reset",
                    style: TextStyle(fontSize: 30.sp, color: AppColor.primary),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedStatus = tempStatus;

                      if (tempRange != null &&
                          tempRange!.startDate != null &&
                          tempRange!.endDate != null) {
                        selectedDateRange = DateTimeRange(
                          start: tempRange!.startDate!,
                          end: tempRange!.endDate!,
                        );
                      }
                    });

                    filterOrders();

                    Navigator.pop(context);
                  },

                  child: Text(
                    "Terapkan",
                    style: TextStyle(fontSize: 30.sp, color: AppColor.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColor.backgroundColorPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Riwayat Penjualan",
                              style: TextStyle(fontSize: 42.sp),
                            ),
                            Text(
                              formatted,
                              style: TextStyle(
                                fontSize: 36.sp,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 600.w,
                        child: Row(
                          children: [
                            IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll<Color>(
                                  AppColor.backgroundColorSecondry,
                                ),
                              ),
                              onPressed: () async {
                                await showDateFilterDialog(context);
                              },

                              icon: const Icon(Icons.date_range),
                            ),
                            Gap(1),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 70.h,
                                  child: SearchBarWidget(
                                    hintText: "Cari Transaksi",
                                    controller: searchController,
                                    onChanged: (value) {
                                      searchQuery = value;

                                      filterOrders();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Gap(10),
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
                  SizedBox(height: 5),

                  Expanded(
                    child: FutureBuilder<List<Order>>(
                      future: _futureOrders,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: AppColor.primary,
                              size: 32,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('Tidak ada data transaksi.'),
                          );
                        }
                        if (allOrders.isEmpty) {
                          allOrders = snapshot.data!;
                          filteredList = snapshot.data!;
                        }
                        return RefreshIndicator(
                          onRefresh: refreshData,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DataTable2(
                              horizontalMargin: 0,
                              columnSpacing: 0,
                              dataTextStyle: TextStyle(
                                fontSize: 30.sp,
                                color: Colors.black,
                              ),
                              headingRowHeight: 60.h,
                              empty: Text("Tidak Ditemukan Data"),
                              fixedLeftColumns: 2,
                              dataRowHeight: 90.h,
                              fixedTopRows: 1,
                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => AppColor.primary,
                              ),
                              dividerThickness: 0.5,
                              headingTextStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 34.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              border: TableBorder(
                                top: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                left: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                right: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                verticalInside: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                                horizontalInside: BorderSide(
                                  color: Colors.black,
                                  width: 0.5,
                                ),
                              ),
                              columns: [
                                DataColumn2(
                                  fixedWidth: 45,
                                  label: Center(child: Text("No")),
                                ),
                                DataColumn2(
                                  label: Center(child: Text('Customer')),
                                ),
                                DataColumn2(
                                  label: Center(child: Text('Nomor HP')),
                                ),
                                DataColumn2(
                                  label: Center(child: Text('Tanggal & Waktu')),
                                  size: ColumnSize.L,
                                  minWidth: 600.w,
                                ),
                                DataColumn2(
                                  label: Center(child: Text('Status Pesanan')),
                                  minWidth: 400.w,
                                ),
                                DataColumn2(
                                  label: Center(child: Text('Aksi')),
                                  minWidth: 610.w,
                                ),
                              ],
                              rows:
                                  filteredList.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final order = entry.value;

                                    return DataRow2(
                                      cells: [
                                        DataCell(
                                          Center(child: Text("${index + 1}")),
                                        ),
                                        DataCell(
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(order.customerName),
                                          ),
                                        ),
                                        DataCell(
                                          Text(order.phoneNumber.toString()),
                                        ),
                                        DataCell(
                                          Column(
                                            children: [
                                              Gap(5),
                                              Text(
                                                formatTime(
                                                  order.transactionTime,
                                                ),
                                              ),
                                              Gap(5),
                                              Center(
                                                child: Container(
                                                  width:
                                                      order.transactionCompleteTime !=
                                                              null
                                                          ? 600.w
                                                          : 250.w,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        order.transactionCompleteTime !=
                                                                null
                                                            ? Colors.green
                                                                .withOpacity(
                                                                  0.1,
                                                                )
                                                            : Colors.orange
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      order.transactionCompleteTime !=
                                                              null
                                                          ? "Selesai • ${formatTime(order.transactionCompleteTime!)}"
                                                          : "Diproses",
                                                      style: TextStyle(
                                                        color:
                                                            order.transactionCompleteTime !=
                                                                    null
                                                                ? Colors.green
                                                                : Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          order.isOrderComplete == 3
                                              ? orderStatusRow(
                                                icon: Icon(
                                                  Icons.check_circle,
                                                  size: 40.sp,
                                                  color: Colors.green,
                                                ),
                                                text: "Selesai",
                                              )
                                              : Theme(
                                                data: ThemeData(
                                                  canvasColor:
                                                      AppColor
                                                          .backgroundColorPrimary,
                                                ),
                                                child: DropdownButton<String>(
                                                  isExpanded: true,
                                                  value:
                                                      order.isOrderComplete
                                                          .toString(),
                                                  items: [
                                                    DropdownMenuItem(
                                                      value: '0',
                                                      child: orderStatusRow(
                                                        icon: FaIcon(
                                                          FontAwesomeIcons
                                                              .solidClock,
                                                          color: Colors.orange,
                                                          size: 40.sp,
                                                        ),

                                                        text: "Antrian",
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '1',
                                                      child: orderStatusRow(
                                                        icon: Icon(
                                                          Icons.work,
                                                          size: 40.sp,
                                                          color: Colors.blue,
                                                        ),
                                                        text: "Proses",
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '2',
                                                      child: orderStatusRow(
                                                        icon: Icon(
                                                          Icons.shopping_bag,
                                                          size: 40.sp,
                                                          color: Colors.purple,
                                                        ),
                                                        text: "Siap Diambil",
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '3',
                                                      child: orderStatusRow(
                                                        icon: Icon(
                                                          Icons.check_circle,
                                                          size: 40.sp,
                                                          color: Colors.green,
                                                        ),
                                                        text: "Selesai",
                                                      ),
                                                    ),
                                                  ],
                                                  onChanged: (newValue) {
                                                    AwesomeDialog(
                                                      descTextStyle: TextStyle(
                                                        fontSize: 30.sp,
                                                      ),
                                                      titleTextStyle: TextStyle(
                                                        fontSize: 34.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      buttonsTextStyle:
                                                          TextStyle(
                                                            fontSize: 30.sp,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      context: context,
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
                                                      keyboardAware: true,
                                                      dialogType:
                                                          DialogType.noHeader,
                                                      btnCancelText: "Tidak",
                                                      btnOkText: "Iya",
                                                      title: "Pemberitahuan",
                                                      desc:
                                                          "Apakah anda yakin ingin melakukan perubahan status pemesanan?",
                                                      btnOkOnPress: () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });
                                                        try {
                                                          final success =
                                                              await ApiService()
                                                                  .updateOrderStatus(
                                                                    order.id,
                                                                    int.parse(
                                                                      newValue!,
                                                                    ),
                                                                    await token,
                                                                  );
                                                          if (!context
                                                              .mounted) {
                                                            return;
                                                          }
                                                          if (success) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                                content: Text(
                                                                  'Status berhasil diupdate',
                                                                ),
                                                              ),
                                                            );

                                                            await _loadData();
                                                          } else {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                content: Text(
                                                                  'Gagal update status',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          print(e);
                                                        } finally {
                                                          if (context.mounted) {
                                                            setState(() {
                                                              _isLoading =
                                                                  false;
                                                            });
                                                          }
                                                        }
                                                      },
                                                      btnCancelOnPress: () {},
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
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  try {
                                                    final api = ApiService();
                                                    final items = await api
                                                        .getOrderItemDetailsWithProduct(
                                                          order.id,
                                                          await token,
                                                        );
                                                    final isConnected =
                                                        await PrintBluetoothThermal
                                                            .connectionStatus;

                                                    if (!isConnected) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              style: TextStyle(
                                                                fontSize: 30.sp,
                                                              ),
                                                              'Printer belum terhubung. Sambungkan terlebih dahulu.',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
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
                                                  } catch (e) {
                                                    print(e);
                                                  } finally {
                                                    if (context.mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    }
                                                  }
                                                },
                                                icon: Icon(
                                                  Icons.print,
                                                  size: 50.sp,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  try {
                                                    final phoneNumber =
                                                        order.phoneNumber
                                                            .toString();
                                                    final statusMap = {
                                                      '0':
                                                          'Sedang dalam antrian',
                                                      '1': 'Sedang diproses',
                                                      '2': 'Siap diambil',
                                                      '3': 'Sudah selesai',
                                                    };
                                                    final status =
                                                        statusMap[order
                                                            .isOrderComplete
                                                            .toString()] ??
                                                        'Belum diketahui';
                                                    final api = ApiService();
                                                    final items = await api
                                                        .getOrderItemDetailsWithProduct(
                                                          order.id,
                                                          await token,
                                                        );
                                                    final message =
                                                        generateOrderMessageText(
                                                          order: order,
                                                          items: items,
                                                          status: status,
                                                        );
                                                    final whatsappUrl = Uri.parse(
                                                      'https://wa.me/62$phoneNumber?text=${Uri.encodeComponent(message)}',
                                                    );
                                                    if (order.phoneNumber ==
                                                            null ||
                                                        order
                                                            .phoneNumber!
                                                            .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          backgroundColor:
                                                              Colors.red,
                                                          content: Text(
                                                            'Gagal membuka WhatsApp tidak ada No. HP',
                                                          ),
                                                        ),
                                                      );
                                                    } else {
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
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              'Gagal membuka WhatsApp',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  } catch (e) {
                                                    print(e);
                                                  } finally {
                                                    if (context.mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    }
                                                  }
                                                },
                                                icon: FaIcon(
                                                  FontAwesomeIcons.whatsapp,
                                                  color: Colors.green,
                                                  size: 50.sp,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.info_outline,
                                                  color: Colors.blue,
                                                  size: 50.sp,
                                                ),
                                                onPressed: () async {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  try {
                                                    final db = ApiService();
                                                    final items = await db
                                                        .getOrderItemDetailsWithProduct(
                                                          order.id,
                                                          await token,
                                                        );
                                                    showOrderDetailDialog(
                                                      context,
                                                      order,
                                                      items,
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Tidak dapat ",
                                                        ),
                                                      ),
                                                    );
                                                  } finally {
                                                    if (context.mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    }
                                                  }
                                                },
                                              ),
                                              if (order.isPaymentComplete
                                                      .toString() ==
                                                  '0')
                                                IconButton(
                                                  onPressed: () async {
                                                    if (order
                                                            .isPaymentComplete ==
                                                        0) {
                                                      final result = await Navigator.push(
                                                        context,
                                                        PageTransition(
                                                          duration:
                                                              Durations.medium4,
                                                          type:
                                                              PageTransitionType
                                                                  .rightToLeft,
                                                          child:
                                                              UpdatePaymentScreen(
                                                                orderData:
                                                                    order,
                                                              ),
                                                        ),
                                                      );
                                                      if (result == true) {
                                                        _loadData();
                                                        setState(() {});
                                                      }
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.payment_rounded,
                                                    color: Colors.red,
                                                    size: 50.sp,
                                                  ),
                                                ),
                                              if (order.isOrderComplete != 3)
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 50.sp,
                                                  ),
                                                  onPressed: () async {
                                                    deleteOrderDialog(
                                                      context,
                                                      order.id,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
                child: Center(
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

                          const SizedBox(height: 16),

                          const Text(
                            "Sedang memproses...",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
