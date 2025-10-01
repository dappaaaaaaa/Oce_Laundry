import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:aplikasi_demo_test/view/setting_screen/cubit/tax_discount_cubit.dart';
import 'package:aplikasi_demo_test/view/setting_screen/cubit/tax_discount_state.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class TaxDiscountSection extends StatefulWidget {
  const TaxDiscountSection({Key? key}) : super(key: key);

  @override
  State<TaxDiscountSection> createState() => _TaxDiscountSectionState();
}

class _TaxDiscountSectionState extends State<TaxDiscountSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isFormVisible = false;
  bool isTaxTab = true;

  bool isEditing = false;
  int? editingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => isTaxTab = _tabController.index == 0);
    });

    context.read<TaxDiscountCubit>().loadData();
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // * Fungsi untuk menampilkan dialog konfirmasi penghapusan
  Future<void> showDeleteDialog(VoidCallback function, bool isTaxTab) async {
    AwesomeDialog(
      context: context,
      width: 500,
      headerAnimationLoop: false,
      title: "Hapus Data ${isTaxTab ? "Pajak" : "Diskon"}?",
      desc:
          "Apakah anda yakin ingin menghapus data ${isTaxTab ? "Pajak" : "Diskon"} ini?",
      dismissOnBackKeyPress: false,
      dismissOnTouchOutside: false,
      btnOkIcon: FontAwesome.trash_solid,
      btnOkText: "Hapus",
      btnCancelText: "Batal",
      dialogBackgroundColor: AppColor.backgroundColorPrimary,
      btnOkOnPress: () {
        function();
      },
      btnCancelOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Kelola Pajak dan Diskon",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Pajak"), Tab(text: "Diskon")],
          indicatorColor: AppColor.primary,
          labelColor: AppColor.primary,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(context, true),
              _buildTabContent(context, false),
            ],
          ),
        ),
      ],
    );
  }

  // * Fungsi untuk membangun konten tab Pajak dan Diskon
  Widget _buildTabContent(BuildContext context, bool isTaxTab) {
    return BlocBuilder<TaxDiscountCubit, TaxDiscountState>(
      builder: (context, state) {
        final data = isTaxTab ? state.taxes : state.discounts;

        return Row(
          children: [
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final nameKey = isTaxTab ? 'tax_name' : 'discount_name';
                  final valueKey = isTaxTab ? 'tax' : 'discount';

                  return Expanded(
                    child: Card(
                      color: AppColor.backgroundColorPrimary,
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          item[nameKey],
                          style: TextStyle(fontSize: 15),
                        ),
                        subtitle: Text("Besaran: ${item[valueKey]} %"),
                        leading:
                            isTaxTab
                                ? Icon(BoxIcons.bxs_badge_dollar)
                                : Icon(Bootstrap.tag_fill),
                        iconColor: AppColor.primary,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                FontAwesome.trash_solid,
                                size: 22,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                showDeleteDialog(() {
                                  if (isTaxTab) {
                                    context.read<TaxDiscountCubit>().deleteTax(
                                      item['id'],
                                    );
                                  } else {
                                    context
                                        .read<TaxDiscountCubit>()
                                        .deleteDiscount(item['id']);
                                  }
                                }, isTaxTab);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                BoxIcons.bx_edit,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                setState(() {
                                  isFormVisible = true;
                                  isEditing = true;
                                  editingId = item['id'];
                                  nameController.text =
                                      item[nameKey].toString();
                                  amountController.text =
                                      item[valueKey].toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const VerticalDivider(),
            SizedBox(
              width: 300,
              child:
                  isFormVisible
                      ? _buildForm(isTaxTab)
                      : ElevatedButton(
                        onPressed:
                            () => setState(() {
                              isFormVisible = true;
                              isEditing = false;
                              nameController.clear();
                              amountController.clear();
                            }),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          maximumSize: Size(100, 60),
                          minimumSize: Size(60, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tambah",
                              style: TextStyle(color: Colors.white),
                            ),
                            Icon(Icons.add),
                          ],
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  // * Fungsi untuk membangun form input Pajak atau Diskon
  Widget _buildForm(bool isTaxTab) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTaxTab ? "Nama Pajak" : "Nama Diskon"),
            const SizedBox(height: 10),
            TextFormField(
              controller: nameController,
              validator:
                  (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
              decoration: CustomTextFieldStyle.inputDecoration(
                hintText: "Masukan Nama ${isTaxTab ? "Pajak" : "Diskon"}",
              ),
            ),
            const SizedBox(height: 20),
            Text(isTaxTab ? "Besaran Pajak (%)" : "Besaran Diskon (%)"),
            const SizedBox(height: 10),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              validator: (val) {
                final v = double.tryParse(val ?? '');
                if (v == null) return 'Harus angka';
                if (v > 100) return 'Maksimal 100%';
                return null;
              },
              decoration: CustomTextFieldStyle.inputDecoration(
                suffix: Icon(Icons.percent, size: 20),
                hintText: "Masukan Besaran ${isTaxTab ? "Pajak" : "Diskon"}",
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isFormVisible = false;
                      isEditing = false;
                      editingId = null;
                      nameController.clear();
                      amountController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    maximumSize: Size(150, 60),
                    minimumSize: Size(130, 50),
                  ),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final name = nameController.text.trim();
                      final amount = double.parse(amountController.text.trim());

                      if (isEditing && editingId != null) {
                        if (isTaxTab) {
                          context.read<TaxDiscountCubit>().updateTax(
                            editingId!,
                            name,
                            amount,
                          );
                        } else {
                          context.read<TaxDiscountCubit>().updateDiscount(
                            editingId!,
                            name,
                            amount,
                          );
                        }
                      } else {
                        if (isTaxTab) {
                          context.read<TaxDiscountCubit>().addTax({
                            'tax_name': name,
                            'tax': amount,
                          });
                        } else {
                          context.read<TaxDiscountCubit>().addDiscount({
                            'discount_name': name,
                            'discount': amount,
                          });
                        }
                      }

                      setState(() {
                        isFormVisible = false;
                        isEditing = false;
                        editingId = null;
                        nameController.clear();
                        amountController.clear();
                      });
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    maximumSize: Size(150, 60),
                    minimumSize: Size(130, 50),
                  ),
                  child: Text(
                    "Simpan",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
