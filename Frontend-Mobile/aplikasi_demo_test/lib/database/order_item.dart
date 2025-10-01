class OrderItem {
  final int? id;
  final int orderId;
  final int productId;
  final double weight;
  final int price;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.weight,
    required this.price,
  });

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    double? weight,
    int? price,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      weight: weight ?? this.weight,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'weight': weight,
      'price': price,
    };
  }
}
