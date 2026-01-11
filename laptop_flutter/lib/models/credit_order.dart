import 'package:intl/intl.dart';
import 'package:laptop_flutter/models/user.dart';

import 'credit_order_detail.dart'; // Sẽ tạo file này

class CreditOrderModel {
  final int id;
  final int userId;
  final int
      status; // 0: Chờ thanh toán, 1: Đã thanh toán, 2: Quá hạn, 3: Đã hủy
  final String? note;
  final int total;
  final DateTime orderDate;
  final DateTime? dueDate;
  final DateTime? paymentDate;
  final UserModel? user; // Thông tin người dùng đặt hàng (cho admin)
  final List<CreditOrderDetailModel>? creditOrderDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditOrderModel({
    required this.id,
    required this.userId,
    required this.status,
    this.note,
    required this.total,
    required this.orderDate,
    this.dueDate,
    this.paymentDate,
    this.user,
    this.creditOrderDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreditOrderModel.fromJson(Map<String, dynamic> json) {
    List<CreditOrderDetailModel>? details;
    if (json['creditOrderDetails'] != null &&
        json['creditOrderDetails'] is List) {
      details = (json['creditOrderDetails'] as List)
          .map((item) =>
              CreditOrderDetailModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Hàm helper để parse int an toàn, trả về defaultValue nếu là null hoặc không parse được
    int _parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double)
        return value.toInt(); // Xử lý trường hợp API trả về số thực
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return CreditOrderModel(
      id: _parseInt(json['id'],
          defaultValue: -1), // -1 để dễ nhận biết nếu ID không có
      userId: _parseInt(json['user_id'], defaultValue: -1),
      status: _parseInt(json['status']), // Mặc định là 0 nếu API không trả về
      note: json['note'] as String?,
      total: _parseInt(json['total']), // Mặc định là 0
      orderDate: DateTime.parse(
              json['order_date'] as String? ?? DateTime.now().toIso8601String())
          .toLocal(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String).toLocal()
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      creditOrderDetails: details,
      createdAt: DateTime.parse(
              json['createdAt'] as String? ?? DateTime.now().toIso8601String())
          .toLocal(),
      updatedAt: DateTime.parse(
              json['updatedAt'] as String? ?? DateTime.now().toIso8601String())
          .toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'note': note,
      'total': total,
      'order_date': orderDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      // Không gửi user và details khi tạo/cập nhật từ client (trừ khi API yêu cầu)
    };
  }

  // Helper để hiển thị ngày tháng
  String get orderDateFormatted =>
      DateFormat('dd/MM/yyyy HH:mm').format(orderDate);
  String? get dueDateFormatted =>
      dueDate != null ? DateFormat('dd/MM/yyyy').format(dueDate!) : 'Chưa có';
  String? get paymentDateFormatted => paymentDate != null
      ? DateFormat('dd/MM/yyyy HH:mm').format(paymentDate!)
      : 'Chưa thanh toán';
}
