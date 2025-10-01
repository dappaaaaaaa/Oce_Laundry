class Discount {
  final int id;
  final String discountName;
  final double discount;

  Discount({
    required this.id,
    required this.discountName,
    required this.discount,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'discount_name': discountName, 'discount': discount};
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['id'],
      discountName: map['discount_name'],
      discount: map['discount'],
    );
  }
}
