import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart'; // << Import Order model

class OrderItemCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderItemCard({super.key, required this.order, this.onTap});

  // Hàm helper để lấy text trạng thái
  String getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chờ xác nhận';
      case 1:
        return 'Chờ lấy hàng';
      case 2:
        return 'Đang giao';
      case 3:
        return 'Đã giao';
      case 4:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  // Hàm helper để lấy màu trạng thái (ví dụ)
  Color getStatusColor(int status, BuildContext context) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.teal;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Lấy format ngày giờ locale Việt Nam
    final formatDate = DateFormat('HH:mm dd/MM/yyyy', 'vi_VN');

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      elevation: 1, // Thêm độ nổi nhẹ
      child: InkWell(
        onTap: onTap, // Để điều hướng đến chi tiết đơn hàng sau này
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Đơn hàng #${order.id}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    getStatusText(order.status),
                    style: TextStyle(
                        color: getStatusColor(order.status, context),
                        fontWeight: FontWeight.bold,
                        fontSize: 13 // Cỡ chữ nhỏ hơn chút
                        ),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Hiển thị thông tin cơ bản khác
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                      'Ngày đặt: ${order.createdAt != null ? formatDate.format(order.createdAt!.toLocal()) : 'N/A'}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[
                              700])), // Chuyển sang giờ địa phương nếu cần
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('Tổng tiền: ${formatCurrency.format(order.total)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),

              // TODO: Hiển thị ảnh và tên sản phẩm đầu tiên nếu có (yêu cầu API trả về include OrderDetail -> Product)
              // if (order.details != null && order.details!.isNotEmpty) ...

              if (onTap != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Xem chi tiết >',
                      style: TextStyle(color: Colors.blue, fontSize: 12)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
