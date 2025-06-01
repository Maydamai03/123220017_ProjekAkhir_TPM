class OrderedProduct {
  final int id;
  final String name;
  final double pricePerUnit;
  final String imageUrl;
  final int quantity;

  OrderedProduct({
    required this.id,
    required this.name,
    required this.pricePerUnit,
    required this.imageUrl,
    required this.quantity,
  });

  factory OrderedProduct.fromCartItem(dynamic cartItem) {
    final product = cartItem.product;
    final quantity = cartItem.quantity;
    return OrderedProduct(
      id: product.id,
      name: product.name,
      pricePerUnit: product.price.toDouble(),
      imageUrl: product.image,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pricePerUnit': pricePerUnit,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    return OrderedProduct(
      id: json['productId'] as int, // <<< Ini yang sering jadi masalah
      name: json['productName'] as String,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      imageUrl: json['productImageUrl'] as String,
      quantity: json['quantity'] as int, // <<< Ini juga bisa jadi masalah
    );
  }
}

// OrderModel (Revisi)
class OrderModel {
  final int? id; // <<< TAMBAHKAN INI! Ini adalah ID unik dari backend.
  int userId;
  String recipientName;
  String deliveryAddress;
  String currency;
  double totalAmount;
  DateTime orderDate;
  List<OrderedProduct> products;

  OrderModel({
    this.id, // <<< TAMBAHKAN INI ke konstruktor
    required this.userId,
    required this.recipientName,
    required this.deliveryAddress,
    required this.currency,
    required this.totalAmount,
    required this.orderDate,
    required this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Biasanya ID tidak dikirim saat membuat pesanan baru
      'userId': userId,
      'recipientName': recipientName,
      'deliveryAddress': deliveryAddress,
      'currency': currency,
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int, // <<< TAMBAHKAN INI untuk membaca ID dari backend
      userId: json['userId'] as int,
      recipientName: json['recipientName'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      currency: json['currency'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderDate: DateTime.parse(json['orderDate'] as String),
      products: (json['items'] as List)
          .map((itemJson) =>
              OrderedProduct.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }
}
