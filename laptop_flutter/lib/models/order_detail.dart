import 'package:laptop_flutter/models/product.dart';

class OrderDetailModel {
  final int id;
  final int price;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int orderId;
  final int productId;
  final ProductModel? products;

  OrderDetailModel({
    required this.id,
    required this.price,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.orderId,
    required this.productId,
    this.products,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'],
      price: json['price'],
      quantity: json['quantity'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      orderId: json['order_id'],
      productId: json['product_id'],
      products: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order_id': orderId,
      'product_id': productId,
      'product': products?.toJson(),
    };
  }

  @override
  List<Object?> get props =>
      [id, price, quantity, orderId, productId, products];
}
