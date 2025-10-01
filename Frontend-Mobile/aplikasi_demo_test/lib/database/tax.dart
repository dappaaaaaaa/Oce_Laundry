class Tax {
  final int id;
  final String taxName;
  final double tax;

  Tax({required this.id, required this.taxName, required this.tax});

  Map<String, dynamic> toMap() {
    return {'id': id, 'tax_name': taxName, 'tax': tax};
  }

  factory Tax.fromMap(Map<String, dynamic> map) {
    return Tax(id: map['id'], taxName: map['tax_name'], tax: map['tax']);
  }
}
