import 'package:aplikasi_demo_test/database/database_helper.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/capitalize_words_formatter.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneNumberController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _searchBarController = SearchController();
  int _charCount = 0;
  final _formKey = GlobalKey<FormState>();
  bool isFormVisible = false;
  int? _editingCustomerId;
  List<Map<String, dynamic>> _allCustomers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  @override
  void initState() {
    super.initState();
    _customerPhoneNumberController.addListener(() {
      setState(() {
        _charCount = _customerPhoneNumberController.text.length;
      });
    });
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneNumberController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  // * Fungsi untuk menyimpan atau memperbarui data pelanggan
  Future<void> _saveCustomer() async {
    final name = _customerNameController.text.trim();
    final phone = _customerPhoneNumberController.text.trim();
    final address = _customerAddressController.text.trim();

    if (_editingCustomerId != null) {
      await DatabaseHelper().updateCustomer(
        id: _editingCustomerId!,
        name: name,
        phone: phone,
        address: address,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelanggan berhasil diperbarui')),
      );
    } else {
      final customer = {
        'customer_name': name,
        'phone_number': phone,
        'address': address,
      };
      await DatabaseHelper().insertCustomer(customer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelanggan berhasil ditambahkan')),
      );
    }

    await _loadCustomers();
    setState(() {
      _editingCustomerId = null;
      isFormVisible = false;
      _customerNameController.clear();
      _customerPhoneNumberController.clear();
      _customerAddressController.clear();
    });
  }

  // * Fungsi untuk menampilkan dialog konfirmasi penghapusan data pelanggan
  Future<void> _showDeleteDialog(Map<String, dynamic> data) async {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      title: "Hapus Data User",
      desc: "Apakah anda yakin untuk mengapus data pelanggan ini?",
      dialogType: DialogType.warning,
      width: 550,
      headerAnimationLoop: false,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      btnOkText: "Hapus",
      btnOkColor: Colors.red,
      btnCancelColor: Colors.green,
      btnCancelText: "Batal",
      btnOkOnPress: () async {
        await DatabaseHelper().deleteCustomer(data['id']);
        setState(() {});
      },
      btnCancelOnPress: () {},
    ).show();
  }

  Future<void> _loadCustomers() async {
    final customers = await DatabaseHelper().getAllCustomer();
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
    });
  }

  void _filterCustomers(String query) {
    final results =
        _allCustomers.where((cust) {
          final name = cust['customer_name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();

    setState(() {
      _filteredCustomers = results;
    });
  }

  // * Fungsi untuk mengisi form dengan data pelanggan yang akan diedit
  Future<void> _editCustomer(Map<String, dynamic> data) async {
    setState(() {
      _editingCustomerId = data['id'];
      _customerNameController.text = data['customer_name'] ?? '';
      _customerPhoneNumberController.text = data['phone_number'].toString();
      _customerAddressController.text = data['address'] ?? '';
      isFormVisible = true;
    });
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColor.backgroundColorPrimary,
      body: KeyboardAvoider(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  // height: 300,
                  width: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchBarWidget(
                        controller: _searchBarController,
                        onChanged: _filterCustomers,
                      ),
                      Gap(16),
                      Text("Daftar Pelanggan", style: TextStyle(fontSize: 24)),

                      SizedBox(height: 30),
                      Expanded(
                        child:
                            _filteredCustomers.isEmpty
                                ? const Center(
                                  child: Text("Tidak Ada data Pelanggan"),
                                )
                                : ListView.builder(
                                  itemCount: _filteredCustomers.length,
                                  itemBuilder: (context, index) {
                                    final cust = _filteredCustomers[index];
                                    return Card(
                                      color: const Color.fromRGBO(
                                        245,
                                        250,
                                        253,
                                        1,
                                      ),
                                      elevation: 3,
                                      child: ListTile(
                                        title: Text(
                                          "Nama: ${cust['customer_name']}",
                                        ),
                                        leading: const Icon(Icons.person),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "No hp: ${cust['phone_number']}",
                                            ),
                                            Text("Alamat: ${cust['address']}"),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed:
                                                  () => _showDeleteDialog(cust),
                                              icon: const Icon(
                                                FontAwesome.trash_solid,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _editCustomer(cust),
                                              icon: const Icon(
                                                BoxIcons.bx_edit,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),

                VerticalDivider(thickness: 1, color: Colors.black),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    // height: 300,
                    width: 450,

                    // * Form untuk menambahkan atau memperbarui data pelanggan
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isFormVisible)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isFormVisible = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              maximumSize: Size(350, 80),
                              minimumSize: Size(300, 60),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Tambahkan Pelanggan Baru",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                Icon(
                                  Bootstrap.person_plus_fill,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),

                        if (isFormVisible)
                          // * Form untuk menambahkan atau memperbarui data pelanggan
                          Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editingCustomerId != null
                                        ? "Perbarui Data Pelanggan"
                                        : "Buat Data Pelanggan",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text("Nama Customer"),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _customerNameController,
                                    keyboardType: TextInputType.name,
                                    inputFormatters: [
                                      CapitalizeWordsFormatter(),
                                    ],
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          hintText: "Masukan Nama Customer",
                                          icon: Icon(Icons.person),
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nama tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  Text("Nomor Telepon Customer"),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _customerPhoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(14),
                                    ],
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          hintText: "Masukan Nomor Hp Customer",
                                          suffixText: "$_charCount/14",
                                          icon: Icon(Icons.phone),
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nomor Telepon tidak boleh kosong';
                                      }
                                      if (value.length < 10) {
                                        return "Nomor Tidak boleh Kurang dari 10";
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  Text("Alamat Customer"),
                                  SizedBox(height: 10),
                                  TextFormField(
                                    controller: _customerAddressController,
                                    keyboardType: TextInputType.streetAddress,
                                    maxLines: 3,
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          icon: Icon(Icons.home),
                                          hintText: "Masukan Alamat Customer",
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Alamat tidak boleh kosong';
                                      }

                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _editingCustomerId = null;
                                            isFormVisible = false;
                                            _customerNameController.clear();
                                            _customerPhoneNumberController
                                                .clear();
                                            _customerAddressController.clear();
                                          });
                                        },

                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          minimumSize: Size(210, 60),
                                        ),

                                        child: Text(
                                          "Batal",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _saveCustomer();
                                              isFormVisible = false;
                                              _customerNameController.clear();
                                              _customerPhoneNumberController
                                                  .clear();
                                              _customerAddressController
                                                  .clear();
                                            });
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          minimumSize: Size(210, 60),
                                        ),

                                        child: Text(
                                          _editingCustomerId != null
                                              ? "Perbarui Data Pelanggan"
                                              : "Buat Data Pelanggan",
                                          style: TextStyle(
                                            color: Colors.white,
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
                      ],
                    ),
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
