class Customer {
  final int id;
  final String customerName;
  final String phoneNumber;
  final String address;

  Customer({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'address': address,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      customerName: map['customer_name'],
      phoneNumber: map['phone_number'],
      address: map['address'],
    );
  }
}
