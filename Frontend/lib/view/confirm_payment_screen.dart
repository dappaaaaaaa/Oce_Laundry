// ignore_for_file: use_build_context_synchronously

import 'package:aplikasi_demo_test/database/database_helper.dart';
import 'package:aplikasi_demo_test/database/order_item.dart';
import 'package:aplikasi_demo_test/database/product.dart';
import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/capitalize_words_formatter.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:aplikasi_demo_test/utils/print_struk.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:aplikasi_demo_test/view/midtrans_payment_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
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
  final api = ApiService();
  String? _username;
  bool _isLoading = false;
  final now = DateTime.now();
  String? _phoneNumberError;
  final _formKey = GlobalKey<FormState>();
  String? _customerNameError;
  int _charCount = 0;
  List<int> dynamicNominal = [];
  final token = AuthService.getToken();

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

  final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
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
              padding: EdgeInsets.all(16.2),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pilih Data Pelanggan",
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(10.h),
                  SearchBarWidget(
                    controller: searchController,
                    onChanged: filterCustomers,
                  ),

                  Gap(10.h),
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

    final totalPayment =
        _paymentMethod == 1
            ? totalHarga
            : int.tryParse(
                  _totalPayment.text.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0;

    final kembalian = totalPayment - totalHarga;
    final tokenValue = await token;

    final order = await ApiService().getOrderById(orderid, tokenValue);

    if (order == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order tidak ditemukan')));

      return;
    }

    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      width: 850.w,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      btnCancelColor: AppColor.primary,
      headerAnimationLoop: false,

      title: "Berhasil",
      desc: "Transaksi berhasil dilakukan",
      btnCancelText: "Print",
      btnOkText: "Selesaikan Pesanan",
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Kasir"),
                    const Text("Nama Customer"),
                    const Text("Nomor Handphone"),
                    const Text("Tanggal"),
                    const Text("Metode Pembayaran"),
                    const Divider(),
                    SizedBox(
                      height: 150.h,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.cart.length,
                        itemBuilder: (context, index) {
                          final item = widget.cart[index];
                          final product = widget.allProducts.firstWhere(
                            (b) => b.id == item.productId,
                          );
                          return Text(
                            '${product.productName} '
                            'x ${item.weight} Kg',
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    const Text("QTY"),
                    const Text("Total"),
                    const Text("Jumlah Pembayaran"),
                    const Text("Kembalian"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_username ?? ""),
                    Text(_customerNameController.text),
                    Text(_phoneNumberController.text),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                    Text(getPaymentMethodLabel(_paymentMethod)),
                    const Divider(),
                    SizedBox(
                      height: 150.h,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.cart.length,
                        itemBuilder: (context, index) {
                          final item = widget.cart[index];
                          final total = item.price * item.weight;
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Text(formatCurrency(total)),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Text(widget.cart.length.toString()),
                    Text(formatCurrency(totalHarga)),
                    Text(_totalPayment.text),
                    Text(kembalian >= 0 ? formatCurrency(kembalian) : 'Rp 0'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      btnCancelOnPress: () async {
        final isConnected = await PrintBluetoothThermal.connectionStatus;

        if (!isConnected) {
          if (!context.mounted) return;

          AwesomeDialog(
            context: context,
            dialogType: DialogType.error,
            animType: AnimType.scale,
            headerAnimationLoop: false,
            width: 450.w,
            dismissOnTouchOutside: false,
            dismissOnBackKeyPress: false,
            dialogBackgroundColor: AppColor.backgroundColorPrimary,
            title: 'Printer Belum Terhubung',
            desc: 'Silakan sambungkan printer terlebih dahulu.',
            btnOkOnPress: () {
              Navigator.pop(context);
              setState(() {
                widget.cart.clear();
              });
            },
          ).show();
          return;
        }
        final itemList =
            widget.cart.map((item) {
              final product = widget.allProducts.firstWhere(
                (b) => b.id == item.productId,
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
                      SizedBox(height: 16.h),
                      Text(
                        isSecondPrint
                            ? "Sedang mencetak struk kedua..."
                            : "Sedang mencetak struk pertama...",
                      ),
                      SizedBox(height: 24.h),
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
                              child: const Text("Lewati Print Kedua"),
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
                              minimumSize: Size(140.w, 50.h),
                            ),
                            child: Text(
                              isSecondPrint ? "Selesai" : "Print Struk Kedua",
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
        if (!isSkipped && context.mounted) {
          dialogSetState(() {
            isSecondPrint = true;
          });
          await cetakStrukLaundryEscPos(order: order, items: itemList);
          await Future.delayed(const Duration(seconds: 10));
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pop(context);
          }
          widget.cart.clear();
        }
      },
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
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0.w),
                child: Row(
                  children: [
                    // *Bagian Kiri
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Nama Produk",
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                                Text(
                                  "Berat",
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                                Text(
                                  "Harga",
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                              ],
                            ),
                            Divider(color: Colors.black),
                            Gap(10),
                            // * Menampilkan daftar pesanan
                            SizedBox(
                              height: 300.h,
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
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0.w,
                                        ),
                                        child: Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    product.productName,
                                                    style: TextStyle(
                                                      fontSize: 30.sp,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      "${item.weight}Kg",
                                                      style: TextStyle(
                                                        fontSize: 30.sp,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    formatCurrency(priceTotal),
                                                    style: TextStyle(
                                                      fontSize: 30.sp,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Gap(200.h),
                            Divider(color: const Color.fromRGBO(0, 0, 0, 1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 250.h,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: TextStyle(fontSize: 30.sp),
                                      ),
                                      Text(
                                        'Pajak ',
                                        style: TextStyle(fontSize: 30.sp),
                                      ),
                                      Text(
                                        'Diskon ',
                                        style: TextStyle(fontSize: 30.sp),
                                      ),
                                      Text(
                                        'Total ',
                                        style: TextStyle(fontSize: 30.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 250.h,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                    ),

                    // * Bagian Kanan
                    SizedBox(width: 20),
                    VerticalDivider(color: Colors.black),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 7,
                      child: Container(
                        width: 620,
                        height: 600,
                        decoration: BoxDecoration(
                          // border: Border.all(color: Colors.black),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 450,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return "Nama Tidak Boleh Kosong";
                                                  }
                                                  return null;
                                                },
                                                controller:
                                                    _customerNameController,
                                                inputFormatters: [
                                                  CapitalizeWordsFormatter(),
                                                ],
                                                decoration:
                                                    CustomTextFieldStyle.inputDecoration(
                                                      hintText:
                                                          "Nama Pelanggan",
                                                      borderRadius: 4,
                                                    ).copyWith(
                                                      isDense: true,
                                                      errorText:
                                                          _customerNameError,
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
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return null;
                                                  }
                                                  if (value.length < 10 ||
                                                      value.length > 14) {
                                                    return "Nomor HP harus 10–14 digit";
                                                  }
                                                  return null;
                                                },
                                                controller:
                                                    _phoneNumberController,
                                                keyboardType:
                                                    TextInputType.phone,

                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    14,
                                                  ),
                                                ],
                                                decoration:
                                                    CustomTextFieldStyle.inputDecoration(
                                                      suffixText:
                                                          "$_charCount/14",
                                                      hintText:
                                                          "Masukan Nomor HP Pelanggan",
                                                      borderRadius: 4,
                                                    ).copyWith(
                                                      isDense: true,
                                                      errorText:
                                                          _phoneNumberError,
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
                                              {
                                                'label': 'Bayar Nanti',
                                                'value': 2,
                                              },
                                            ].map((method) {
                                              final isSelected =
                                                  _paymentMethod ==
                                                  method['value'];

                                              return ChoiceChip(
                                                label: Text(
                                                  method['label'] as String,
                                                ),

                                                selected: isSelected,

                                                onSelected: (_) {
                                                  setState(() {
                                                    _paymentMethod =
                                                        method['value'] as int;
                                                  });

                                                  // VALIDATE ULANG
                                                  _formKey.currentState
                                                      ?.validate();
                                                },

                                                selectedColor:
                                                    AppColor.buttonColor,

                                                backgroundColor:
                                                    Colors.grey[300],

                                                labelStyle: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),

                                                avatar: null,

                                                showCheckmark: false,

                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),

                                                  side: BorderSide(
                                                    color:
                                                        isSelected
                                                            ? AppColor
                                                                .buttonColor
                                                            : Colors.grey,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(color: Colors.black),

                                      const SizedBox(height: 8),
                                      const Text("Jumlah Pembayaran"),
                                      const SizedBox(height: 16),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: 50,
                                          maxWidth: 300,
                                        ),
                                        child: TextFormField(
                                          controller: _totalPayment,
                                          keyboardType: TextInputType.number,

                                          validator: (value) {
                                            final cleanValue = value
                                                ?.replaceAll(
                                                  RegExp(r'[^0-9]'),
                                                  '',
                                                );

                                            final number = int.tryParse(
                                              cleanValue ?? '',
                                            );

                                            if (_paymentMethod == 0) {
                                              if (cleanValue == null ||
                                                  cleanValue.isEmpty) {
                                                return 'Jumlah pembayaran wajib di isi';
                                              }

                                              if (number == null ||
                                                  number <= 0) {
                                                return "Jumlah pembayaran wajib di isi";
                                              }

                                              if (number < total) {
                                                return "Jumlah pembayaran kurang dari total";
                                              }
                                            }

                                            if (_paymentMethod == 2) {
                                              if (cleanValue != null &&
                                                  cleanValue.isNotEmpty) {
                                                if (number != null &&
                                                    number > total) {
                                                  return "Jumlah pembayaran lebih dari total";
                                                }
                                              }
                                            }

                                            return null;
                                          },

                                          onChanged: (value) {
                                            setState(() {
                                              _totalPayment.clear();
                                            });
                                            final numericString = value
                                                .replaceAll(
                                                  RegExp(r'[^0-9]'),
                                                  '',
                                                );

                                            final numericValue =
                                                int.tryParse(numericString) ??
                                                0;

                                            final formatted = formatCurrency(
                                              numericValue,
                                            );

                                            _totalPayment
                                                .value = TextEditingValue(
                                              text: formatted,
                                              selection:
                                                  TextSelection.collapsed(
                                                    offset: formatted.length,
                                                  ),
                                            );
                                          },

                                          decoration:
                                              CustomTextFieldStyle.inputDecoration(
                                                borderRadius: 4,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

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
                                                final isHargaPas =
                                                    amount == total;

                                                return ElevatedButton(
                                                  onPressed: () {
                                                    _totalPayment.text =
                                                        formatCurrency(amount);
                                                    _totalPayment.selection =
                                                        TextSelection.collapsed(
                                                          offset:
                                                              _totalPayment
                                                                  .text
                                                                  .length,
                                                        );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColor.buttonColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    minimumSize: const Size(
                                                      140,
                                                      40,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isHargaPas
                                                        ? 'Uang Pas'
                                                        : formatCurrency(
                                                          amount,
                                                        ),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      SizedBox(height: 20),
                                      if (_paymentMethod == 2)
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                _totalPayment
                                                    .text = formatCurrency(0);
                                                _totalPayment.selection =
                                                    TextSelection.collapsed(
                                                      offset:
                                                          _totalPayment
                                                              .text
                                                              .length,
                                                    );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    AppColor.buttonColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                minimumSize: const Size(
                                                  110,
                                                  40,
                                                ),
                                              ),
                                              child: const Text(
                                                'Belum Bayar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 50.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                try {
                                                  final totalValue =
                                                      int.tryParse(
                                                        _totalPayment.text
                                                            .replaceAll(
                                                              RegExp(r'[^0-9]'),
                                                              '',
                                                            ),
                                                      );

                                                  final phoneValue =
                                                      int.tryParse(
                                                        _phoneNumberController
                                                            .text,
                                                      );

                                                  final totalPayment =
                                                      _paymentMethod == 1
                                                          ? total
                                                          : totalValue ?? 0;

                                                  if (_paymentMethod == 1) {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              _,
                                                            ) => MidtransPaymentScreen(
                                                              amount: total,
                                                              customerName:
                                                                  _customerNameController
                                                                      .text,
                                                              customerPhone:
                                                                  phoneValue
                                                                      .toString(),
                                                            ),
                                                      ),
                                                    );

                                                    if (result != true) {
                                                      if (!context.mounted)
                                                        return;

                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Pembayaran QRIS dibatalkan',
                                                          ),
                                                        ),
                                                      );

                                                      return;
                                                    }
                                                  }

                                                  final orderId = await api.postOrder({
                                                    'total_payment':
                                                        totalPayment,
                                                    'sub_total': subTotal,
                                                    'tax': tax,
                                                    'discount': discount,
                                                    'total': total,
                                                    'total_item':
                                                        widget.cart.length,
                                                    'payment_method':
                                                        _paymentMethod,
                                                    'transaction_time':
                                                        formatted,
                                                    'transaction_complete_time':
                                                        null,
                                                    'customer_name':
                                                        _customerNameController
                                                            .text,
                                                    'phone_number':
                                                        _phoneNumberController
                                                            .text,
                                                    'cashier_name': _username,
                                                    'is_sync': 1,
                                                    'is_order_complete': 0,
                                                    'is_payment_complete':
                                                        _paymentMethod == 2
                                                            ? 0
                                                            : 1,
                                                  }, await token);

                                                  if (orderId == null) {
                                                    throw Exception(
                                                      'Gagal membuat order',
                                                    );
                                                  }

                                                  for (final item
                                                      in widget.cart) {
                                                    final success = await api
                                                        .postOrderItem({
                                                          'order_id': orderId,
                                                          'products_id':
                                                              item.productId,
                                                          'price': item.price,
                                                          'weight': item.weight,
                                                        }, await token);

                                                    if (!success) {
                                                      throw Exception(
                                                        'Gagal mengirim item ${item.productId}',
                                                      );
                                                    }
                                                  }

                                                  if (!context.mounted) return;

                                                  await _paymentAlert(orderId);
                                                } catch (e) {
                                                  if (!context.mounted) return;

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Terjadi kesalahan: $e',
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
                                              }
                                            },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColor.buttonColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size(280, 60),
                                    ),
                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Text(
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
      ),
    );
  }
}
