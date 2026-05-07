class Order {
  final int? id;
  final int totalPayment;
  final int subTotal;
  final int tax;
  final int discount;
  final int total;
  final String paymentMethod;
  final int transactionTime;
  int? transactionCompleteTime;
  final String customerName;
  String? phoneNumber;
  final String cashierName;
  final int totalItem;
  final int isSync;
  final int isOrderComplete;
  final int isPaymentComplete;

  Order({
    this.id,
    required this.totalPayment,
    required this.subTotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.totalItem,
    required this.paymentMethod,
    required this.transactionTime,
    this.transactionCompleteTime,
    required this.customerName,
    this.phoneNumber,
    required this.cashierName,
    this.isSync = 0,
    this.isOrderComplete = 0,
    this.isPaymentComplete = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_payment': totalPayment,
      'sub_total': subTotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'total_item': totalItem,
      'payment_method': paymentMethod,
      'transaction_time': transactionTime,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'cashier_name': cashierName,
      'is_sync': isSync,
      'transaction_complete_time': transactionCompleteTime,
      // Jika butuh simpan status complete juga:
      'is_order_complete': isOrderComplete,
      'is_payment_complete': isPaymentComplete,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      totalPayment: map['total_payment'],
      subTotal: map['sub_total'],
      tax: map['tax'],
      discount: map['discount'],
      total: map['total'],
      paymentMethod: map['payment_method'],
      transactionTime: map['transaction_time'],
      customerName: map['customer_name'],
      cashierName: map['cashier_name'],
      totalItem: map['total_item'],
      phoneNumber: map['phone_number'],
      transactionCompleteTime: map['transaction_complete_time'],
    );
  }
}
