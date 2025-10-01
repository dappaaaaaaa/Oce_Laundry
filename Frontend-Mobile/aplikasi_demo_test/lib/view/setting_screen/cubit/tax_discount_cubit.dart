import 'package:aplikasi_demo_test/database/database_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tax_discount_state.dart';

class TaxDiscountCubit extends Cubit<TaxDiscountState> {
  // * Inisialisasi state awal
  TaxDiscountCubit() : super(TaxDiscountState());

  // * Memuat data pajak dan diskon saat inisialisasi
  Future<void> loadData() async {
    emit(state.copyWith(loading: true));
    final taxes = await DatabaseHelper().getAllTax();
    final discounts = await DatabaseHelper().getAllDiscount();
    emit(state.copyWith(taxes: taxes, discounts: discounts, loading: false));
  }

  // * Mengambil data pajak dan diskon
  Future<void> addTax(Map<String, dynamic> tax) async {
    await DatabaseHelper().insertTax(tax);
    await loadData();
  }

  // * Menghapus data pajak dan diskon
  Future<void> deleteTax(int id) async {
    await DatabaseHelper().deleteTax(id);
    await loadData();
  }

  // * Memperbarui data pajak dan diskon
  Future<void> updateTax(int id, String name, double amount) async {
    await DatabaseHelper().updateTax(id: id, taxName: name, tax: amount);
    await loadData();
  }

  // * Menambahkan, menghapus, dan memperbarui diskon
  Future<void> addDiscount(Map<String, dynamic> discount) async {
    await DatabaseHelper().insertDiscount(discount);
    await loadData();
  }

  Future<void> deleteDiscount(int id) async {
    await DatabaseHelper().deleteDiscount(id);
    await loadData();
  }

  Future<void> updateDiscount(int id, String name, double amount) async {
    await DatabaseHelper().updateDiscount(
      id: id,
      discountName: name,
      discount: amount,
    );
    await loadData();
  }
}
