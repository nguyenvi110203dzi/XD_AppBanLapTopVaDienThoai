import 'package:laptop_flutter/models/user.dart'; // Giả sử bạn có UserModel
// import 'package:laptop_flutter/models/order.dart'; // Giả sử bạn có OrderModel

class InventoryTransactionModel {
  final int id;
  final int productId;
  final String transactionType; // 'import', 'export', etc.
  final int quantityChange;
  final DateTime transactionDate;
  final int? userId;
  final UserModel? user; // Thông tin người thực hiện giao dịch
  final int? orderId;
  // final OrderModel? order; // Thông tin đơn hàng liên quan (nếu có)
  final String? notes;
  final String? reason; // Lý do xuất kho

  InventoryTransactionModel({
    required this.id,
    required this.productId,
    required this.transactionType,
    required this.quantityChange,
    required this.transactionDate,
    this.userId,
    this.user,
    this.orderId,
    // this.order,
    this.notes,
    this.reason,
  });

  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'],
      productId: json['product_id'],
      transactionType: json['transaction_type'],
      quantityChange: json['quantity_change'],
      transactionDate: DateTime.parse(json['transaction_date']).toLocal(),
      userId: json['user_id'],
      user: json['User'] != null ? UserModel.fromJson(json['User']) : null,
      orderId: json['order_id'],
      // order: json['Order'] != null ? OrderModel.fromJson(json['Order']) : null,
      notes: json['notes'],
      reason: json['reason'],
    );
  }
}
