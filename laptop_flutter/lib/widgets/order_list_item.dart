import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/order.dart';

class OrderListItem extends StatelessWidget {
  final OrderModel order;
  final Map<String, dynamic>
      statusInfo; // Nhận thông tin trạng thái từ màn hình list
  final VoidCallback onTap; // Hàm xử lý khi nhấn vào item

  const OrderListItem(
      {super.key,
      required this.order,
      required this.statusInfo, // Thêm tham số này
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Định dạng tiền tệ Việt Nam
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        // Cho phép nhấn vào cả Card
        borderRadius: BorderRadius.circular(10),
        onTap: onTap, // Gọi hàm onTap khi nhấn
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .center, // Căn giữa các thành phần theo chiều dọc
            children: [
              // --- Cột Trái: ID và Trạng thái ---
              SizedBox(
                width: 90, // Giới hạn chiều rộng để căn chỉnh đẹp hơn
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '#${order.id}', // Hiển thị ID đơn hàng
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      // Widget nhỏ gọn hiển thị trạng thái
                      label: Text(
                        statusInfo['text'], // Lấy text trạng thái từ map
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                      backgroundColor:
                          statusInfo['color'], // Lấy màu trạng thái từ map
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // Thu nhỏ vùng chạm
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- Cột Phải: Thông tin Khách hàng, Ngày, Tổng tiền ---
              Expanded(
                // Chiếm hết không gian còn lại
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Căn trái nội dung
                  children: [
                    Text(
                      // Hiển thị tên khách hàng, nếu không có thì hiện 'N/A'
                      'KH: ${order.user?.name ?? 'N/A'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1, // Chỉ hiển thị 1 dòng
                      overflow: TextOverflow.ellipsis, // Thêm ... nếu quá dài
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Hiển thị ngày đặt hàng đã định dạng
                      'Ngày: ${DateFormat('dd/MM/yy HH:mm').format(order.createdAt.toLocal())}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    // Hiển thị số điện thoại nếu có
                    if (order.user?.phone?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'SĐT: ${order.user!.phone}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Hiển thị tổng tiền nếu có
                    if (order.total != null)
                      Text(
                        'Tổng: ${formatCurrency.format(order.total)}', // Định dạng tiền tệ
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              // --- Icon điều hướng ---
              Icon(Icons.chevron_right,
                  color: Colors.grey[400]), // Icon mũi tên >
            ],
          ),
        ),
      ),
    );
  }
}
