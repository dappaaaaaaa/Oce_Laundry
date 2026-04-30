import 'package:aplikasi_demo_test/database/database_helper.dart';
import 'package:aplikasi_demo_test/database/order_item.dart';
import 'package:aplikasi_demo_test/database/product.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/capitalize_words_formatter.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:aplikasi_demo_test/utils/print_struk.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:aplikasi_demo_test/view/midtrans_payment_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../service/auth_service.dart';

class ConfirmPaymentScreen extends StatefulWidget {
  final List<OrderItem> cart;
  final List<Product> allProducts;
  final double tax;
  final double discount;

  const ConfirmPaymentScreen({
    super.key,
    required this.cart,
    required this.allProducts,
    required this.tax,
    required this.discount,
  });

  @override
  State<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends State<ConfirmPaymentScreen> {
  final _customerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _totalPayment = TextEditingController();
  int _paymentMethod = 0;
  final db = DatabaseHelper();
  String? _username;
  final now = DateTime.now();
  String? _totalPaymentError;
  String? _phoneNumberError;
  String? _customerNameError;
  int _charCount = 0;
  List<int> dynamicNominal = [];

  @override
  void initState() {
    super.initState();
    if (_totalPayment.text.isEmpty) {
      _totalPayment.text = formatCurrency(0);
    }
    _loadUserData();
    _phoneNumberController.addListener(() {
      setState(() {
        _charCount = _phoneNumberController.text.length;
      });
    });
  }

  // * Memuat data pengguna dari layanan otentikasi
  Future<void> _loadUserData() async {
    final user = await AuthService.getUserData();
    setState(() {
      _username = user?['username'] ?? 'Kasir';
    });
  }

  // * Menampilkan bottom sheet pemilih pelanggan
  Future<void> _showCustomerPicker() async {
    final customers = await DatabaseHelper().getAllCustomer();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.backgroundColorPrimary,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final searchController = SearchController();
        List<Map<String, dynamic>> filteredCustomers = List.from(customers);

        return StatefulBuilder(
          builder: (context, setState) {
            void filterCustomers(String query) {
              setState(() {
                filteredCustomers =
                    customers.where((customer) {
                      final name =
                          customer['customer_name'].toString().toLowerCase();
                      final phone =
                          customer['phone_number'].toString().toLowerCase();
                      return name.contains(query.toLowerCase()) ||
                          phone.contains(query.toLowerCase());
                    }).toList();
              });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Data Pelanggan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SearchBarWidget(
                    controller: searchController,
                    onChanged: filterCustomers,
                  ),

                  const SizedBox(height: 10),
                  Expanded(
                    child:
                        filteredCustomers.isEmpty
                            ? const Center(child: Text("Tidak ada pelanggan"))
                            : ListView.builder(
                              itemCount: filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return ListTile(
                                  title: Text(customer['customer_name']),
                                  subtitle: Text(
                                    customer['phone_number'].toString(),
                                  ),
                                  onTap: () {
                                    _customerNameController.text =
                                        customer['customer_name'];
                                    _phoneNumberController.text =
                                        customer['phone_number'].toString();
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // * Format angka menjadi string dengan pemisah ribuan
  String formatNumber(num value) {
    return NumberFormat.decimalPattern('id_ID').format(value);
  }

  // * Mendapatkan label metode pembayaran berdasarkan nilai
  String getPaymentMethodLabel(int value) {
    switch (value) {
      case 0:
        return "Cash";
      case 1:
        return "QRIS";
      case 2:
        return "Belum Bayar";
      default:
        return "Tidak diketahui";
    }
  }

  // * Menampilkan dialog konfirmasi pembayaran
  Future<void> _paymentAlert(int orderid) async {
    final totalHarga = widget.cart.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.weight).toInt(),
    );
    // int tax = (totalHarga * (widget.tax / 100)).toInt();
    // int discount = (totalHarga * (widget.discount / 100)).toInt();
    final totalPayment =
        _paymentMethod == 1
            ? totalHarga
            : int.tryParse(
                  _totalPayment.text.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0;

    final kembalian = totalPayment - totalHarga;

    AwesomeDialog(
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      context: context,
      width: 550,
      headerAnimationLoop: false,
      dialogType: DialogType.success,
      btnCancelColor: AppColor.primary,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,

      title: "Berhasil",
      desc: "Transaksi Berhasil di Lakukan",
      btnCancelText: "Print",
      btnOkText: "Selesaikan Pesanan",
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kolom Kiri
            SizedBox(
              height: 350,
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kasir"),
                  Text("Nama Customer"),
                  Text("Nomor Handphone"),
                  Text("Tanggal Transaksi"),
                  Text("Metode Pembayaran"),
                  Divider(thickness: 1),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart[index];
                        final product = widget.allProducts.firstWhere(
                          (b) => b.id == item.productId,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '${product.productName} x ${item.weight} Kg',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 1),
                  Text("QTY"),
                  Text("Total"),
                  Text("Jumlah Pembayaran"),
                  Text("Kembalian"),
                ],
              ),
            ),
            // Kolom Kanan
            SizedBox(
              height: 350,
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_username.toString()),
                  Text(_customerNameController.text),
                  Text(_phoneNumberController.text),
                  Text(formatTime(DateTime.now().millisecondsSinceEpoch)),
                  Text(getPaymentMethodLabel(_paymentMethod)),
                  Divider(thickness: 1),
                  // List Produk
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.cart.length,
                      itemBuilder: (context, index) {
                        final item = widget.cart[index];

                        final hargaTotal = item.weight * item.price;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(hargaTotal),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(thickness: 1),
                  Text(widget.cart.length.toString()),
                  Text(
                    formatCurrency((totalHarga)),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _totalPayment.text,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    kembalian >= 0 ? formatCurrency(kembalian) : 'Rp 0',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // * Tombol untuk mencetak struk
      btnCancelOnPress: () async {
        final isConnected = await PrintBluetoothThermal.connectionStatus;

        if (!isConnected) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.scale,
            headerAnimationLoop: false,
            width: 550,
            dismissOnTouchOutside: false,
            dismissOnBackKeyPress: false,
            dialogBackgroundColor: AppColor.backgroundColorPrimary,
            title: 'Printer Belum Terhubung',
            desc:
                'Silakan sambungkan printer terlebih dahulu.\nUntuk mencetak struk lagi anda\ndapat mengakses ke halaman history',
            btnCancelOnPress: () {
              widget.cart.clear();
              Navigator.pop(context);
            },
          ).show();
          return;
        }

        final db = DatabaseHelper();
        final order = await db.getOrderById(orderid);
        if (order == null) {
          print('Order tidak ditemukan');
          return;
        }

        final List<Map<String, dynamic>> itemList =
            widget.cart.map((item) {
              final product = widget.allProducts.firstWhere(
                (b) => b.id == item.productId,
                orElse:
                    () => Product(
                      id: 0,
                      productName: 'Tidak ditemukan',
                      price: item.price,
                    ),
              );

              return {
                'product_name': product.productName,
                'weight': item.weight,
                'price': item.price,
              };
            }).toList();

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
                                widget.cart.clear();
                                Navigator.pop(context);
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
                                  items: itemList,
                                );
                                await Future.delayed(
                                  const Duration(seconds: 10),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }
                                widget.cart.clear();
                              } else if (!isFinished) {
                                isFinished = true;
                                widget.cart.clear();
                                Navigator.pop(context);
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

        await cetakStrukLaundryEscPos(order: order, items: itemList);

        await Future.delayed(const Duration(seconds: 10));

        if (!isSecondPrint && !isSkipped && context.mounted) {
          dialogSetState(() {
            isSecondPrint = true;
          });

          await cetakStrukLaundryEscPos(order: order, items: itemList);

          await Future.delayed(const Duration(seconds: 10));
          if (context.mounted) Navigator.pop(context);
          widget.cart.clear();
        }
      },

      // * Tombol untuk menyelesaikan pesanan
      btnOkOnPress: () {
        setState(() {
          widget.cart.clear();
        });
        Navigator.pop(context);
      },
    ).show();
  }

  // * Format angka menjadi string mata uang Indonesia
  String formatCurrency(num number) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  // * Format waktu menjadi string dengan format dd/MM/yyyy HH:mm
  String formatTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    int subTotal = widget.cart.fold(
      0,
      (total, item) => total + (item.weight * item.price).toInt(),
    );

    int tax = (subTotal * (widget.tax / 100)).toInt();
    int discount = (subTotal * (widget.discount / 100)).toInt();
    int total = subTotal + tax - discount;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.backgroundColorPrimary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // *Bagian Kiri
                SizedBox(
                  width: 380,
                  height: 600,

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Nama Produk", style: TextStyle(fontSize: 18)),
                          Text("Berat", style: TextStyle(fontSize: 18)),
                          Text("Harga", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      Divider(color: Colors.black),
                      SizedBox(height: 10),
                      // * Menampilkan daftar pesanan
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: widget.cart.length,
                          itemBuilder: (context, index) {
                            final item = widget.cart[index];
                            final product = widget.allProducts.firstWhere(
                              (b) => b.id == item.productId,
                            );
                            final priceTotal = item.weight * item.price;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Container(
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            product.productName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Center(
                                            child: Text(
                                              "${item.weight}Kg",
                                              style: const TextStyle(
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formatCurrency(priceTotal),
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Divider(color: const Color.fromRGBO(0, 0, 0, 1)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 140,

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text('Pajak ', style: TextStyle(fontSize: 18)),
                                Text('Diskon ', style: TextStyle(fontSize: 18)),
                                Text('Total ', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 160,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(subTotal),
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  formatCurrency(tax),
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  formatCurrency(discount),
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  formatCurrency(total),
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // * Bagian Kanan
                SizedBox(width: 20),
                VerticalDivider(color: Colors.black),
                SizedBox(width: 20),
                Container(
                  width: 620,
                  height: 600,
                  decoration: BoxDecoration(
                    // border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 450,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      FontAwesome.address_book_solid,
                                      color: AppColor.primary,
                                      size: 35,
                                    ),
                                    onPressed: () {
                                      _showCustomerPicker();
                                    },
                                  ),
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 50,
                                        maxWidth: 300,
                                      ),
                                      child: TextField(
                                        controller: _customerNameController,
                                        inputFormatters: [
                                          CapitalizeWordsFormatter(),
                                        ],
                                        decoration:
                                            CustomTextFieldStyle.inputDecoration(
                                              hintText: "Nama Pelanggan",
                                              borderRadius: 4,
                                            ).copyWith(
                                              isDense: true,
                                              errorText: _customerNameError,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 50,
                                        maxWidth: 300,
                                      ),
                                      child: TextField(
                                        controller: _phoneNumberController,
                                        keyboardType: TextInputType.phone,

                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(14),
                                        ],
                                        decoration:
                                            CustomTextFieldStyle.inputDecoration(
                                              suffixText: "$_charCount/14",
                                              hintText:
                                                  "Masukan Nomor HP Pelanggan",
                                              borderRadius: 4,
                                            ).copyWith(
                                              isDense: true,
                                              errorText: _phoneNumberError,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              Divider(color: Colors.black),
                              const SizedBox(height: 12),

                              Text("Metode Bayar"),

                              Wrap(
                                spacing: 12,
                                children:
                                    [
                                      {'label': 'Cash', 'value': 0},
                                      {'label': 'QRIS', 'value': 1},
                                      {'label': 'Bayar Nanti', 'value': 2},
                                    ].map((method) {
                                      final isSelected =
                                          _paymentMethod == method['value'];

                                      return ChoiceChip(
                                        label: Text(method['label'] as String),
                                        selected: isSelected,
                                        onSelected: (_) {
                                          setState(() {
                                            _paymentMethod =
                                                method['value'] as int;
                                          });
                                        },

                                        selectedColor: AppColor.buttonColor,
                                        backgroundColor: Colors.grey[300],
                                        labelStyle: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                        avatar: null,
                                        showCheckmark: false,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color:
                                                isSelected
                                                    ? AppColor.buttonColor
                                                    : Colors.grey,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.black),
                              if (_paymentMethod == 0) ...[
                                const SizedBox(height: 8),
                                const Text("Jumlah Pembayaran"),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: 50,
                                    maxWidth: 300,
                                  ),
                                  child: TextField(
                                    controller: _totalPayment,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final numericString = value.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );

                                      final numericValue =
                                          int.tryParse(numericString) ?? 0;

                                      final formatted = formatCurrency(
                                        numericValue,
                                      );

                                      _totalPayment.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    },
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          borderRadius: 4,
                                        ).copyWith(
                                          isDense: true,
                                          errorText: _totalPaymentError,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              SizedBox(height: 20),
                              if (_paymentMethod == 0)
                                Wrap(
                                  spacing: 20,
                                  children:
                                      [
                                        total,
                                        10000,
                                        20000,
                                        30000,
                                        50000,
                                        60000,
                                        100000,
                                        200000,
                                      ].map((amount) {
                                        final isHargaPas = amount == total;

                                        return ElevatedButton(
                                          onPressed: () {
                                            _totalPayment.text = formatCurrency(
                                              amount,
                                            );
                                            _totalPayment.selection =
                                                TextSelection.collapsed(
                                                  offset:
                                                      _totalPayment.text.length,
                                                );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor:
                                                AppColor.buttonColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            minimumSize: const Size(140, 40),
                                          ),
                                          child: Text(
                                            isHargaPas
                                                ? 'Uang Pas'
                                                : formatCurrency(amount),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),

                              if (_paymentMethod == 2) ...[
                                const Text("Jumlah Pembayaran"),
                                const SizedBox(height: 16),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: 50,
                                    maxWidth: 300,
                                  ),
                                  child: TextField(
                                    controller: _totalPayment,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final numericString = value.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );

                                      final numericValue =
                                          int.tryParse(numericString) ?? 0;

                                      final formatted = formatCurrency(
                                        numericValue,
                                      );

                                      _totalPayment.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    },
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          borderRadius: 4,
                                        ).copyWith(
                                          isDense: true,
                                          errorText: _totalPaymentError,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              SizedBox(height: 20),
                              if (_paymentMethod == 2)
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _totalPayment.text = formatCurrency(0);
                                        _totalPayment.selection =
                                            TextSelection.collapsed(
                                              offset: _totalPayment.text.length,
                                            );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: AppColor.buttonColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        minimumSize: const Size(110, 40),
                                      ),
                                      child: const Text(
                                        'Belum Bayar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColor.buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(280, 60),
                            ),
                            child: Text(
                              "Kembali",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          ElevatedButton(
                            onPressed: () async {
                              final db = DatabaseHelper();
                              final now = DateTime.now();
                              final totalValue = int.tryParse(
                                _totalPayment.text.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                ),
                              );
                              final phoneValue = int.tryParse(
                                _phoneNumberController.text,
                              );

                              String? customerError;
                              String? phoneError;
                              String? paymentError;
                              bool hasError = false;

                              if (_customerNameController.text.isEmpty) {
                                customerError = "Masukan Nama Pelanggan";
                                hasError = true;
                              }

                              if (_phoneNumberController.text.isEmpty ||
                                  phoneValue == null) {
                                phoneError = "Nomor Hp Tidak Boleh kosong";
                                hasError = true;
                              } else if (_phoneNumberController.text.length <
                                      10 ||
                                  _phoneNumberController.text.length > 14) {
                                phoneError = "Nomor HP harus 10–14 digit";
                                hasError = true;
                              }

                              if (_paymentMethod == 0) {
                                if (_totalPayment.text.isEmpty ||
                                    totalValue == null ||
                                    totalValue <= 0) {
                                  paymentError =
                                      "Masukan jumlah pembayaran yang valid";
                                  hasError = true;
                                } else if (totalValue < total) {
                                  paymentError =
                                      "Jumlah pembayaran kurang dari total";
                                  hasError = true;
                                }
                              }

                              if (_paymentMethod == 2 &&
                                  (totalValue == null || totalValue > total)) {
                                paymentError =
                                    "Jumlah pembayaran lebih dari total";
                                hasError = true;
                              }

                              if (hasError) {
                                setState(() {
                                  _customerNameError = customerError;
                                  _phoneNumberError = phoneError;
                                  _totalPaymentError = paymentError;
                                });
                                return;
                              }

                              final totalPayment =
                                  _paymentMethod == 1
                                      ? total // QRIS langsung total
                                      : totalValue ?? 0;

                              if (_paymentMethod == 1) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => MidtransPaymentScreen(
                                          amount: total,
                                          customerName:
                                              _customerNameController.text,
                                          customerPhone: phoneValue.toString(),
                                        ),
                                  ),
                                );

                                if (result == true) {
                                  final orderId = await db.insertOrder({
                                    'total_payment': total,
                                    'sub_total': subTotal,
                                    'tax': tax,
                                    'discount': discount,
                                    'total': total,
                                    'total_item': widget.cart.length,
                                    'payment_method': 1,
                                    'transaction_time':
                                        now.millisecondsSinceEpoch,
                                    'transaction_complete_time': null,
                                    'customer_name':
                                        _customerNameController.text,
                                    'phone_number': phoneValue ?? 0,
                                    'cashier_name': _username,
                                    'is_sync': 0,
                                    'is_order_complete': 0,
                                    'is_payment_complete': 1,
                                  });
                                  _paymentAlert(orderId);
                                  for (final item in widget.cart) {
                                    await db.insertOrderItem(
                                      item.copyWith(orderId: orderId),
                                    );
                                  }

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pembayaran QRIS berhasil dan disimpan',
                                      ),
                                    ),
                                  );
                                  return;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Pembayaran QRIS dibatalkan',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              if (_paymentMethod == 2) {
                                final orderId = await db.insertOrder({
                                  'total_payment': totalPayment,
                                  'sub_total': subTotal,
                                  'tax': tax,
                                  'discount': discount,
                                  'total': total,
                                  'total_item': widget.cart.length,
                                  'payment_method': 2,
                                  'transaction_time':
                                      now.millisecondsSinceEpoch,
                                  'transaction_complete_time': null,
                                  'customer_name': _customerNameController.text,
                                  'phone_number': phoneValue ?? 0,
                                  'cashier_name': _username,
                                  'is_sync': 0,
                                  'is_order_complete': 0,
                                  'is_payment_complete': 0,
                                });
                                _paymentAlert(orderId);
                                for (final item in widget.cart) {
                                  await db.insertOrderItem(
                                    item.copyWith(orderId: orderId),
                                  );
                                }

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transaksi berhasil disimpan',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final orderId = await db.insertOrder({
                                'total_payment': totalPayment,
                                'sub_total': subTotal,
                                'tax': tax,
                                'discount': discount,
                                'total': total,
                                'total_item': widget.cart.length,
                                'payment_method': _paymentMethod,
                                'transaction_time': now.millisecondsSinceEpoch,
                                'transaction_complete_time': null,
                                'customer_name': _customerNameController.text,
                                'phone_number': phoneValue ?? 0,
                                'cashier_name': _username,
                                'is_sync': 0,
                                'is_order_complete': 0,
                                'is_payment_complete': 1,
                              });
                              _paymentAlert(orderId);

                              for (final item in widget.cart) {
                                await db.insertOrderItem(
                                  item.copyWith(orderId: orderId),
                                );
                              }

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaksi berhasil disimpan'),
                                ),
                              );
                            },

                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColor.buttonColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(280, 60),
                            ),
                            child: const Text(
                              'Konfirmasi Pembayaran',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
