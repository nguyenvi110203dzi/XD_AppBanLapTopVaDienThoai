import 'package:laptop_flutter/models/product.dart'; // Sử dụng ProductModel hiện có

class CreditOrderDetailModel {
  final int id;
  final int creditOrderId;
  final int productId;
  final int price; // Giá tại thời điểm mua
  final int quantity;
  final ProductModel? product; // Thông tin sản phẩm (để hiển thị)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditOrderDetailModel({
    required this.id,
    required this.creditOrderId,
    required this.productId,
    required this.price,
    required this.quantity,
    this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreditOrderDetailModel.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return CreditOrderDetailModel(
      id: _parseInt(json['id'], defaultValue: -1),
      creditOrderId: _parseInt(json['credit_order_id'], defaultValue: -1),
      productId: _parseInt(json['product_id'], defaultValue: -1),
      price: _parseInt(json['price']),
      quantity: _parseInt(json['quantity'],
          defaultValue: 1), // Mặc định số lượng là 1 nếu null
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(
              json['createdAt'] as String? ?? DateTime.now().toIso8601String())
          .toLocal(),
      updatedAt: DateTime.parse(
              json['updatedAt'] as String? ?? DateTime.now().toIso8601String())
          .toLocal(),
    );
  }
}
