import 'dart:io';

import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/capitalize_words_formatter.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:aplikasi_demo_test/utils/search_bar_widget.dart';
import 'package:aplikasi_demo_test/utils/variable.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final stockName = TextEditingController();
  final stockQuantity = TextEditingController();
  final stockUnit = TextEditingController();
  final stockDesciption = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<dynamic> stockList = [];
  bool isLoading = true;
  final ApiService stockService = ApiService();
  String? selectedValue;
  int? _editingStockId;
  bool isFormShow = false;
  File? selectedImage;
  String? existingImage;
  String? selectedSort;
  final searchController = SearchController();
  List<dynamic> filteredList = [];
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await stockService.getStocks();

      setState(() {
        stockList = data;
        filteredList = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ada Kesalahan Server"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteData(int id) async {
    final success = await stockService.deleteStock(id);

    if (success) {
      fetchData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> showDeleteDialog(int id) async {
    AwesomeDialog(
      context: context,
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      title: "Hapus Data Stok",
      desc: "Apakah anda yakin untuk mengapus data Stok ini?",
      dialogType: DialogType.warning,
      width: 400,
      headerAnimationLoop: false,
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      btnOkText: "Hapus",
      btnOkColor: Colors.red,
      btnCancelColor: Colors.green,
      btnCancelText: "Batal",
      btnCancelOnPress: () {},
      btnOkOnPress: () => deleteData(id),
    ).show();
  }

  Future<void> saveData() async {
    setState(() {
      isLoading = true;
    });
    if (_editingStockId != null) {
      setState(() {
        isLoading = true;
      });

      final success = await stockService.updateStock(
        id: _editingStockId!,
        nama: stockName.text,
        kuantitas: int.parse(stockQuantity.text),
        unit: selectedValue ?? "",
        keterangan: stockDesciption.text,
        image: selectedImage,
      );

      setState(() {
        isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Data berhasil diupdate")));
      }
    } else {
      final success = await stockService.createStock(
        nama: stockName.text,
        kuantitas: int.parse(stockQuantity.text),
        unit: selectedValue ?? "",
        keterangan: stockDesciption.text,
        image: selectedImage,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok berhasil ditambahkan")),
        );
      }
    }

    setState(() {
      isLoading = false;
    });

    await fetchData();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // biar tidak terlalu besar
    );

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Ambil dari Galeri"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Ambil dari Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    setState(() {
      _editingStockId = data['id'];
      stockName.text = data['nama'] ?? '';
      stockQuantity.text = data["kuantitas"].toString();
      selectedValue = data['unit'];
      stockDesciption.text = data['keterangan'] ?? "";
      isFormShow = true;

      existingImage =
          data['image'] != null
              ? "${Variable.storageBaseUrl}${data['image']}"
              : null;

      selectedImage = null;
    });
  }

  void searchData(String query) {
    final result =
        stockList.where((item) {
          final nama = item['nama'].toString().toLowerCase();
          return nama.contains(query.toLowerCase());
        }).toList();

    setState(() {
      filteredList = result;
    });
  }

  void sortData(String value) {
    setState(() {
      selectedSort = value;

      if (value == "Nama A-Z") {
        filteredList.sort(
          (a, b) => a['nama'].toString().compareTo(b['nama'].toString()),
        );
      } else if (value == "Nama Z-A") {
        filteredList.sort(
          (a, b) => b['nama'].toString().compareTo(a['nama'].toString()),
        );
      } else if (value == "Kuantitas Terbesar") {
        filteredList.sort(
          (a, b) => int.parse(
            b['kuantitas'].toString(),
          ).compareTo(int.parse(a['kuantitas'].toString())),
        );
      } else if (value == "Kuantitas Terkecil") {
        filteredList.sort(
          (a, b) => int.parse(
            a['kuantitas'].toString(),
          ).compareTo(int.parse(b['kuantitas'].toString())),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 300,
                        child: SearchBarWidget(
                          controller: searchController,
                          hintText: "Cari Data Stok",
                          onChanged: searchData,
                        ),
                      ),
                      Gap(100),
                      DropdownButton<String>(
                        dropdownColor: AppColor.backgroundColorPrimary,
                        value: selectedSort,
                        hint: Text("Urutkan"),
                        items:
                            [
                              "Nama A-Z",
                              "Nama Z-A",
                              "Kuantitas Terbesar",
                              "Kuantitas Terkecil",
                            ].map((e) {
                              return DropdownMenuItem(value: e, child: Text(e));
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            sortData(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Gap(20),
            Expanded(
              child: Row(
                children: [
                  // * Bagian Kiri
                  Expanded(
                    child: SizedBox(
                      child:
                          isLoading
                              ? Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: AppColor.primary,
                                  size: 40,
                                ),
                              )
                              : RefreshIndicator(
                                onRefresh: () => fetchData(),
                                child: GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 5,
                                        crossAxisSpacing: 5,
                                        childAspectRatio: 3 / 4.8,
                                      ),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredList[index];
                                    return Card(
                                      color: AppColor.backgroundColorSecondry,
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: () async {
                                                    updateData(item);
                                                  },
                                                  icon: Icon(
                                                    size: 20,
                                                    Icons.edit,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    showDeleteDialog(
                                                      item['id'],
                                                    );
                                                  },
                                                  icon: Icon(
                                                    size: 20,
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            /// GAMBAR
                                            Center(
                                              child: Image.network(
                                                "${Variable.storageBaseUrl}${item['image']}",
                                                width: 160.w,
                                                height: 100.h,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Image.asset(
                                                    width: 160.w,
                                                    height: 100.h,
                                                    fit: BoxFit.cover,
                                                    "assets/icon/placeholder.png",
                                                  );
                                                },
                                              ),
                                            ),

                                            SizedBox(height: 16),

                                            /// DATA
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          style: TextStyle(
                                                            fontSize: 28.sp,
                                                          ),
                                                          item["nama"],
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      SizedBox(width: 18.w),
                                                      Text(
                                                        style: TextStyle(
                                                          fontSize: 28.sp,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        maxLines: 2,
                                                        "${item["kuantitas"]} ${item["unit"]}",
                                                      ),
                                                    ],
                                                  ),
                                                  Gap(10),
                                                  Text(
                                                    item["keterangan"] ?? "",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                  ),
                  VerticalDivider(color: Colors.black, thickness: 1),
                  // * Bagian Kanan
                  SingleChildScrollView(
                    child: SizedBox(
                      width: 600.w,
                      child: Column(
                        children: [
                          if (!isFormShow)
                            Align(
                              alignment: AlignmentGeometry.center,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isFormShow = true;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  minimumSize: Size(300.w, 80.h),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Tambahkan Stok Baru",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34.sp,
                                      ),
                                    ),
                                    Icon(
                                      Bootstrap.box2,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          if (isFormShow)
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editingStockId != null
                                        ? "Perbarui Data Stok"
                                        : "Buat Data Stok",
                                    style: TextStyle(
                                      fontSize: 30.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Gap(20),
                                  TextFormField(
                                    style: TextStyle(fontSize: 30.sp),
                                    controller: stockName,
                                    inputFormatters: [
                                      CapitalizeWordsFormatter(),
                                    ],
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          labelText: "Nama Stok",
                                          hintText: "Masukan Nama Stok",
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nama stok tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  Gap(15),
                                  TextFormField(
                                    style: TextStyle(fontSize: 30.sp),
                                    keyboardType: TextInputType.number,
                                    controller: stockQuantity,
                                    inputFormatters: [
                                      CapitalizeWordsFormatter(),
                                    ],
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          labelText: "Kuantiti Stok",
                                          hintText: "Masukan Kuantiti Stok",
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Kuantiti tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  Gap(15),
                                  DropdownButtonFormField<String>(
                                    style: TextStyle(
                                      fontSize: 30.sp,
                                      color: Colors.black,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Unit tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                    dropdownColor:
                                        AppColor.backgroundColorPrimary,
                                    value: selectedValue,
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          labelText: "Unit Stok",
                                          hintText: "Pilih Unit Stok",
                                        ),
                                    items:
                                        [
                                          "Pcs",
                                          "Sachet",
                                          "Box",
                                          "L",
                                          "Ml",
                                          "Botol",
                                          "Kg",
                                        ].map((item) {
                                          return DropdownMenuItem(
                                            value: item,
                                            child: Text(item),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedValue = value;
                                      });
                                    },
                                  ),
                                  Gap(15),
                                  TextFormField(
                                    style: TextStyle(fontSize: 30.sp),
                                    controller: stockDesciption,
                                    maxLines: 4,
                                    inputFormatters: [
                                      CapitalizeWordsFormatter(),
                                    ],
                                    decoration:
                                        CustomTextFieldStyle.inputDecoration(
                                          labelText: "Deskripsi Stok",
                                          hintText: "Masukan Deskrpsi Stok",
                                        ),
                                  ),
                                  Gap(15),
                                  selectedImage != null
                                      ? GestureDetector(
                                        onTap: showImageSourceDialog,
                                        child: Image.file(
                                          selectedImage!,
                                          height: 100,
                                        ),
                                      )
                                      : GestureDetector(
                                        onTap: showImageSourceDialog,
                                        child: Container(
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: Text("Belum ada gambar"),
                                          ),
                                        ),
                                      ),

                                  Gap(15),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          minimumSize: Size(120.w, 80.h),
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            selectedValue = null;
                                            isFormShow = false;
                                            stockDesciption.clear();
                                            stockName.clear();
                                            stockQuantity.clear();
                                            _editingStockId = null;
                                            selectedImage = null;
                                          });
                                        },
                                        child: Text(
                                          "Batal",
                                          style: TextStyle(
                                            fontSize: 28.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: AppColor.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          minimumSize: Size(120.w, 80.h),
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            await saveData();
                                            setState(() {
                                              selectedValue = null;
                                              isFormShow = false;
                                              stockDesciption.clear();
                                              stockName.clear();
                                              stockQuantity.clear();
                                              _editingStockId = null;
                                              selectedImage = null;
                                            });
                                          }
                                        },
                                        child: Text(
                                          _editingStockId != null
                                              ? "Perbarui Data Stok"
                                              : "Buat Data Stok",
                                          style: TextStyle(
                                            fontSize: 28.sp,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
