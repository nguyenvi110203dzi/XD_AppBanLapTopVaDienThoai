import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/user.dart';

import 'order_detail.dart'; // Import OrderDetailModel

class OrderModel extends Equatable {
  final int id;
  final int userId;
  final int status;
  final String? note;
  final int? total;
  final int paymentMethod;
  final UserModel? user;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Thường thì API sẽ trả về danh sách chi tiết đơn hàng kèm theo
  final List<OrderDetailModel>? details;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    this.note,
    this.total,
    required this.paymentMethod,
    this.user,
    required this.createdAt,
    required this.updatedAt,
    this.details,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Xử lý danh sách orderDetails nếu có trong JSON
    List<OrderDetailModel>? dsdetail;
    final detailsJsonKey =
        json.containsKey('orderDetails') ? 'orderDetails' : 'order_details';
    if (json[detailsJsonKey] != null && json[detailsJsonKey] is List) {
      dsdetail = <OrderDetailModel>[]; // Khởi tạo list rỗng
      for (var item in (json[detailsJsonKey] as List)) {
        try {
          // Đảm bảo item là Map trước khi parse
          if (item is Map<String, dynamic>) {
            dsdetail.add(OrderDetailModel.fromJson(item));
          } else {
            print(
                "[OrderModel] Skipping invalid detail item (not a Map): $item for order ID: ${json['id']}");
          }
        } catch (e) {
          // Log lỗi parse chi tiết và bỏ qua item lỗi thay vì dừng cả quá trình
          print(
              "[OrderModel] Error parsing detail item: $e for order ID: ${json['id']}. Item data: $item");
          // Có thể thêm item lỗi vào một danh sách riêng nếu cần debug kỹ hơn
        }
      }
    } else {
      dsdetail = [];
    }
    UserModel? parsedUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      try {
        parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
      } catch (e) {
        print(
            "[OrderModel] Error parsing user data: $e for order ID: ${json['id']}");
        parsedUser = null;
      }
    } else {
      // Log ra nếu không tìm thấy key 'user' hoặc nó không phải Map
      print(
          "[OrderModel] User key ('user') not found or invalid in JSON for order ID: ${json['id']}");
      parsedUser = null;
    }

    // Parse DateTime an toàn
    DateTime parsedCreatedAt = DateTime.now(); // Giá trị mặc định nếu lỗi
    DateTime parsedUpdatedAt = DateTime.now(); // Giá trị mặc định nếu lỗi
    try {
      if (json['createdAt'] != null) {
        parsedCreatedAt = DateTime.parse(json['createdAt']);
      } else {
        print("[OrderModel] createdAt is null for order ID: ${json['id']}");
      }
    } catch (e) {
      print(
          "[OrderModel] Error parsing createdAt: ${json['createdAt']} for order ID: ${json['id']} - Error: $e");
    }
    try {
      if (json['updatedAt'] != null) {
        parsedUpdatedAt = DateTime.parse(json['updatedAt']);
      } else {
        print("[OrderModel] updatedAt is null for order ID: ${json['id']}");
      }
    } catch (e) {
      print(
          "[OrderModel] Error parsing updatedAt: ${json['updatedAt']} for order ID: ${json['id']} - Error: $e");
    }

    return OrderModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      status: json['status'] as int? ?? -1,
      note: json['note'] as String?,
      total: json['total'] as int?,
      paymentMethod: json['payment_method'] as int? ?? 0,
      user: parsedUser,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      details: dsdetail ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'note': note,
      'total': total,
      'payment_method': paymentMethod as int? ?? 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order_details': details?.map((detail) => detail.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        status,
        note,
        total,
        paymentMethod,
        user,
        createdAt,
        updatedAt,
        details
      ];
}
