class Order {
  final int id;
  final int totalPayment;
  final int subTotal;
  final int tax;
  final int discount;
  final int total;
  final String paymentMethod;
  final String transactionTime;
  String? transactionCompleteTime;
  final String customerName;
  String? phoneNumber;
  final String cashierName;
  final int totalItem;
  final int isSync;
  final int isOrderComplete;
  final int isPaymentComplete;

  Order({
    required this.id,
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

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: int.tryParse(map['id'].toString()) ?? 0,
      totalPayment: int.tryParse(map['total_payment'].toString()) ?? 0,
      subTotal: int.tryParse(map['sub_total'].toString()) ?? 0,
      tax: int.tryParse(map['tax'].toString()) ?? 0,
      discount: int.tryParse(map['discount'].toString()) ?? 0,
      total: int.tryParse(map['total'].toString()) ?? 0,
      totalItem: int.tryParse(map['total_item'].toString()) ?? 0,
      paymentMethod: map['payment_method'].toString(),
      transactionTime: map['transaction_time'] ?? '',
      transactionCompleteTime: map['transaction_complete_time']?.toString(),
      customerName: map['customer_name'] ?? '',
      phoneNumber: map['phone_number'].toString(),
      cashierName: map['cashier_name'] ?? '',
      isSync: int.tryParse(map['is_sync']?.toString() ?? '0') ?? 0,
      isOrderComplete: int.tryParse(map['is_order_complete'].toString()) ?? 0,
      isPaymentComplete:
          int.tryParse(map['is_payment_complete'].toString()) ?? 0,
    );
  }
}
