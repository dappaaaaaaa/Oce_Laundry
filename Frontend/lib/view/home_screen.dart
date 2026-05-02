import 'dart:async';
import 'package:aplikasi_demo_test/database/product.dart';
import 'package:aplikasi_demo_test/database/database_helper.dart';
import 'package:aplikasi_demo_test/database/order_item.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:aplikasi_demo_test/view/confirm_payment_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int userId;

  const HomeScreen({super.key, required this.username, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> _futureProduct = Future.value([]);
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  List<dynamic> filteredList = [];
  List<dynamic> stockList = [];
  List<OrderItem> cart = [];
  String _searchQuery = '';
  List<Product> allProducts = [];
  List<String> _categories = [];
  final searchController = SearchController();
  List<String> _selectedCategories = [];
  TextEditingController weightController = TextEditingController();
  String _formattedDateTime = '';
  Timer? _timer;
  double discountPercentage = 0.0;
  double taxPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All';
    _selectedCategories = ['All'];
    _loadCategories();
    _loadProducts();
    _startDateTimeUpdater();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // *Method Mengambil Category

  Future<void> _startDateTimeUpdater() async {
    _timer = Timer.periodic(Duration(seconds: 0), (_) {
      final now = DateTime.now();
      String formatted = DateFormat(
        'EEEE, d MMMM yyyy, HH:mm:ss',
        'id_ID',
      ).format(now);

      setState(() {
        _formattedDateTime = formatted;
      });
    });
  }

  // *Method Edit dan Menampilkan Dialog Produk
  Future<void> _editItemWeight(OrderItem item) async {
    final controller = TextEditingController(text: item.weight.toString());
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: const Text('Edit Berat'),
          backgroundColor: AppColor.backgroundColorPrimary,
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Berat dalam Kg (contoh: 1.5)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Masukkan Berat yang valid";
                }
                if (double.tryParse(value) == null) {
                  return "Harus berupa angka";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColor.primary),
              ),
            ),
            ElevatedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(120, 40),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newWeight = double.tryParse(controller.text);
                  setState(() {
                    final index = cart.indexWhere(
                      (i) => i.productId == item.productId,
                    );
                    if (index != -1) {
                      cart[index] = item.copyWith(weight: newWeight);
                    }
                  });
                  Navigator.pop(context);
                  weightController.clear();
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // *Method Tambah dan Menampilkan Dialog Order
  Future<void> addOrderItemFromProducts(Product product) async {
    double weight = 0.0;
    final focusNode = FocusNode();
    await showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });

        return AlertDialog(
          backgroundColor: AppColor.backgroundColorPrimary,
          title: Text('Masukkan Berat untuk ${product.productName}'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: weightController,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Berat dalam Kg (contoh: 1.5)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Masukkan Berat yang valid";
                  }
                  if (double.tryParse(value) == null) {
                    return "Harus berupa angka";
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                weightController.clear();
                Navigator.pop(context);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColor.primary),
              ),
            ),
            ElevatedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(120, 40),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final input = double.tryParse(weightController.text);
                  weight = input!;
                  setState(() {
                    cart.add(
                      OrderItem(
                        productId: product.id,
                        weight: weight,
                        price: product.price,
                        orderId: 0,
                      ),
                    );
                  });

                  weightController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Tambahkan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void searchData(String query) {
    setState(() {
      _searchQuery = query;
    });

    _loadProducts();
  }

  // * Method Ambil Produk Dari Database
  Future<void> _loadProducts() async {
    final db = DatabaseHelper();

    final semuaProductList = await db.getAllProducts();

    List<Product> filteredList = semuaProductList;

    // Filter kategori
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filteredList =
          filteredList.where((b) => b.category == _selectedCategory).toList();
    }

    // Filter search
    if (_searchQuery.isNotEmpty) {
      filteredList =
          filteredList.where((product) {
            return product.productName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();
    }

    setState(() {
      allProducts = semuaProductList;
      _futureProduct = Future.value(filteredList);
    });
  }

  Future<void> _loadCategories() async {
    try {
      final dbHelper = DatabaseHelper();

      final categories = await dbHelper.getCategories();

      setState(() {
        _categories = ['All', ...categories];
        _selectedCategories =
            _selectedCategory != null ? [_selectedCategory!] : ['All'];
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saat memuat kategori: $e');
      }
    }
  }

  // * Method Refresh Data
  Future<void> refreshData() async {
    _loadProducts();
  }

  // *Method Menampilkan Dialog Filter
  Future<void> _showCategoryFilterDialog(BuildContext context) async {
    List<String> tempSelected = List.from(_selectedCategories);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColor.backgroundColorPrimary,
          title: Text(
            'Pilih Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _categories.map((category) {
                    final selected = tempSelected.contains(category);
                    return ChoiceChip(
                      showCheckmark: false,
                      backgroundColor: AppColor.backgroundColorPrimary,
                      label: Text(
                        category,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Color.fromRGBO(35, 90, 110, 1),
                      onSelected: (_) {
                        (context as Element).markNeedsBuild();
                        tempSelected.clear();
                        tempSelected.add(category);
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Reset', style: TextStyle(color: AppColor.primary)),
              onPressed: () {
                setState(() {
                  _selectedCategories = ['All'];
                  _selectedCategory = 'All';
                });

                _loadProducts();

                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Terapkan'),
              onPressed: () {
                setState(() {
                  _selectedCategories = tempSelected;
                  _selectedCategory =
                      tempSelected.isNotEmpty ? tempSelected.first : 'All';
                });

                _loadProducts();

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // * Fungsi Format Harga
  String formatCurrency(num number) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  // * Fungsi Untuk Menampilkan Pajak
  Future<void> showTaxDialog() async {
    final taxs = await DatabaseHelper().getAllTax();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColor.backgroundColorPrimary,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 300,
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pilih Pajak",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: taxs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text("Tanpa Pajak"),
                          subtitle: const Text("0%"),
                          onTap: () {
                            setState(() {
                              taxPercentage = 0.0;
                            });
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        final tax = taxs[index - 1];
                        return ListTile(
                          title: Text(tax['tax_name']),
                          subtitle: Text("${tax['tax']}%"),
                          onTap: () {
                            setState(() {
                              taxPercentage = tax['tax'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // * Fungsi Untuk Menampilkan Diskon
  Future<void> showDiscountDialog() async {
    final discounts = await DatabaseHelper().getAllDiscount();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColor.backgroundColorPrimary,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 300,
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pilih Diskon",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: discounts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text("Tanpa Diskon"),
                          subtitle: const Text("0%"),
                          onTap: () {
                            setState(() {
                              discountPercentage = 0.0;
                            });
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        final tax = discounts[index - 1];
                        return ListTile(
                          title: Text(tax['discount_name']),
                          subtitle: Text("${tax['discount']}%"),
                          onTap: () {
                            setState(() {
                              discountPercentage = tax['discount'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder:
          (context, child) => Scaffold(
            resizeToAvoidBottomInset: false,

            backgroundColor: AppColor.backgroundColorPrimary,
            body: SafeArea(
              child: Row(
                children: [
                  // * Bagian Kiri
                  SizedBox(
                    height: 655.h,
                    width: 190.w,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selamat Datang ${widget.username}",
                            style: TextStyle(fontSize: 8.sp),
                          ),
                          Text(
                            _formattedDateTime,
                            style: TextStyle(
                              fontSize: 6.sp,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 40),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                iconAlignment: IconAlignment.start,
                                icon: Icon(Icons.filter_alt_rounded, size: 18),
                                label: Text(
                                  "Filter: $_selectedCategory",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onPressed:
                                    () => _showCategoryFilterDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 10.h,
                                  ),
                                ),
                              ),

                              Gap(10),

                              Expanded(
                                child: SearchBarWidget(
                                  controller: searchController,
                                  hintText: "Cari Barang",
                                  onChanged: (value) {
                                    searchData(value);
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),
                          Expanded(
                            child: FutureBuilder<List<Product>>(
                              future: _futureProduct,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(child: Text("data"));
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }
                                final products = snapshot.data ?? [];

                                if (products.isEmpty) {
                                  return const Center(
                                    child: Text('Tidak Ada Produk'),
                                  );
                                }
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    _loadProducts();
                                    await Future.delayed(
                                      const Duration(milliseconds: 500),
                                    );
                                  },

                                  // *Menampilkan Produk
                                  child: GridView.builder(
                                    itemCount: products.length,

                                    itemBuilder: (context, index) {
                                      final product = products[index];
                                      return InkWell(
                                        radius: 18,
                                        customBorder: RoundedRectangleBorder(),
                                        onTap: () {
                                          addOrderItemFromProducts(product);
                                        },
                                        child: Card(
                                          color:
                                              AppColor.backgroundColorPrimary,
                                          elevation: 4,
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: Image.asset(
                                                    "assets/icon/placeholder.png",
                                                    scale: 28,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  product.productName,
                                                  style: TextStyle(
                                                    fontSize: 5.sp,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      product.category ??
                                                          'Tanpa Kategori',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 4.sp,
                                                      ),
                                                    ),
                                                    Text(
                                                      formatCurrency(
                                                        product.price,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 4.sp,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          childAspectRatio: 3 / 3,
                                          crossAxisCount: 3,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(color: Colors.grey),

                  // *Bagian Kanan
                  SizedBox(
                    height: 655.h,
                    width: 120.w,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text("Nama Produk"),
                              Text("Berat"),
                              Text("Harga"),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // *Bagian Kanan
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              itemCount: cart.length,
                              itemBuilder: (context, index) {
                                final item = cart[index];
                                final product = allProducts.firstWhere(
                                  (b) => b.id == item.productId,
                                  orElse:
                                      () => Product(
                                        id: 0,
                                        categoryId: null,
                                        category: '',
                                        productName: 'Tidak ditemukan',
                                        description: '',
                                        image: null,
                                        price: 0,
                                        status: 0,
                                      ),
                                );

                                final priceTotal = item.weight * product.price;
                                return InkWell(
                                  onTap: () => _editItemWeight(item),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Container(
                                          height: 30,
                                          alignment: Alignment.center,
                                          child: Dismissible(
                                            key: Key(item.productId.toString()),
                                            onDismissed: (direction) {
                                              setState(() {
                                                cart.removeAt(index);
                                              });
                                            },

                                            background: Container(
                                              color: Color(0xFFE55151),
                                              alignment: Alignment.centerRight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                  ),
                                              child: const Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
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
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Text(
                                                      "${item.weight}Kg",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    formatCurrency(priceTotal),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Column(
                              children: [
                                if (cart.isNotEmpty)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          showTaxDialog();
                                        },
                                        icon: Icon(
                                          BoxIcons.bxs_badge_dollar,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              40,
                                            ),
                                          ),
                                          maximumSize: Size(45, 45),
                                          minimumSize: (Size(45, 45)),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDiscountDialog();
                                        },
                                        icon: Icon(
                                          Bootstrap.tags_fill,
                                          color: Colors.white,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              45,
                                            ),
                                          ),
                                          maximumSize: Size(45, 45),
                                          minimumSize: (Size(45, 45)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey),
                          const Text(
                            "Ringkasan Pesanan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(flex: 1),
                          SizedBox(
                            height: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 130,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Item",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Total Berat",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Pajak",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Diskon",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Total Harga",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 130,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text("${cart.length}"),

                                          Text(
                                            "${cart.fold<double>(0, (total, item) => total + item.weight).toStringAsFixed(1)} Kg",
                                          ),
                                          Text("${taxPercentage.toString()} %"),
                                          Text(
                                            "${discountPercentage.toString()} %",
                                          ),
                                          Text(
                                            " ${formatCurrency(cart.fold<int>(0, (total, item) {
                                              final product = allProducts.firstWhere((b) => b.id == item.productId, orElse: () => Product(id: 0, categoryId: null, category: '', productName: '', description: '', image: '', price: 0, status: 0));
                                              return total + (product.price * item.weight).toInt();
                                            }))}",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Spacer(flex: 1),
                          ElevatedButton(
                            onPressed:
                                cart.isEmpty
                                    ? null
                                    : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ConfirmPaymentScreen(
                                                cart: cart,
                                                allProducts: allProducts,
                                                tax: taxPercentage,
                                                discount: discountPercentage,
                                              ),
                                        ),
                                      );
                                    },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColor.buttonColor,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),

                              minimumSize: (Size(double.infinity, 50)),
                            ),
                            child: Text(
                              "Lanjutkan Pembayaran",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
