class TaxDiscountState {
  final bool loading;
  final List<Map<String, dynamic>> taxes;
  final List<Map<String, dynamic>> discounts;

  TaxDiscountState({
    this.loading = false,
    this.taxes = const [],
    this.discounts = const [],
  });

  // * Metode untuk membuat salinan dari state dengan nilai yang diperbarui
  TaxDiscountState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? taxes,
    List<Map<String, dynamic>>? discounts,
  }) {
    return TaxDiscountState(
      loading: loading ?? this.loading,
      taxes: taxes ?? this.taxes,
      discounts: discounts ?? this.discounts,
    );
  }
}
