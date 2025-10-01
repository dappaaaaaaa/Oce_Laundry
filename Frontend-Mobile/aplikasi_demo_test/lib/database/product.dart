class Product {
  final int id;
  final int? categoryId;
  final String? category;
  final String productName;
  final String? description;
  final String? image;
  final int price;
  final int? status;

  Product({
    required this.id,
    this.categoryId,
    this.category,
    required this.productName,
    this.description,
    this.image,
    required this.price,
    this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      category: json['category'],
      productName: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      price: json['price'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category': category,
      'name': productName,
      'description': description,
      'image': image,
      'price': price,
      'status': status,
    };
  }
}
