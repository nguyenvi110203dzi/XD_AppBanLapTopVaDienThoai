import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/order_detail/order_detail_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../repositories/order_repository.dart'; // Cần để tạo bloc

class OrderDetailScreen extends StatelessWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  String getStatusText(int? status) {
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
      case null:
        return 'Không rõ';
      default:
        return 'Không xác định';
    }
  }

  Color getStatusColor(int? status, BuildContext context) {
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
      case null:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final formatDate = DateFormat('HH:mm dd/MM/yyyy', 'vi_VN');

    return BlocProvider(
      create: (context) => OrderDetailBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(LoadOrderDetail(orderId)), // Load chi tiết ngay khi tạo
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết đơn hàng #$orderId'),
        ),
        body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
          builder: (context, state) {
            if (state is OrderDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderDetailError) {
              return Center(
                  child: Text('Lỗi tải chi tiết đơn hàng: ${state.message}'));
            }
            if (state is OrderDetailLoaded) {
              final order = state.order;
              final user = order.user; // User đặt hàng
              final details = order.details ?? []; // Danh sách sản phẩm

              // Tính lại tổng tiền hàng (subtotal) từ details
              final subtotal = details.fold(
                  0, (sum, item) => sum + (item.price * item.quantity));
              final shippingFee = 0; // Tạm thời chưa có phí ship

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Thông tin đơn hàng ---
                    _buildSectionTitle(context, 'Thông tin đơn hàng'),
                    _buildInfoRow('Mã đơn hàng:', '#${order.id}'),
                    _buildInfoRow(
                        'Ngày đặt hàng:',
                        order.createdAt != null
                            ? formatDate.format(order.createdAt!.toLocal())
                            : 'N/A'),
                    Row(
                      // Hiển thị trạng thái với màu
                      children: [
                        const Text('Trạng thái:',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(
                          getStatusText(order.status),
                          style: TextStyle(
                              color: getStatusColor(order.status, context),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (order.note != null && order.note!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', order.note!),
                    const Divider(height: 32),

                    // --- Thông tin người nhận ---
                    _buildSectionTitle(context, 'Thông tin người nhận'),
                    if (user != null) ...[
                      _buildInfoRow('Người nhận:', user.name),
                      _buildInfoRow(
                          'Số điện thoại:', user.phone ?? 'Chưa cập nhật'),
                      _buildInfoRow('Email:', user.email),
                      // TODO: Thêm địa chỉ chi tiết nếu có
                    ] else
                      const Text('Không có thông tin người nhận.'),
                    const Divider(height: 32),

                    // --- Chi tiết sản phẩm ---
                    _buildSectionTitle(
                        context, 'Chi tiết sản phẩm (${details.length})'),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: details.length,
                      itemBuilder: (context, index) {
                        final detail = details[index];
                        final product =
                            detail.products; // Lấy product từ detail
                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              // Dùng Image.network cho ảnh sản phẩm
                              child: (product?.image != null &&
                                      product!.image!.isNotEmpty &&
                                      Uri.tryParse(product.image!)
                                              ?.hasAbsolutePath ==
                                          true)
                                  ? Image.network(
                                      AppConstants.baseUrl + product.image!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported))
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                          Icons.image_not_supported)),
                            ),
                          ),
                          title: Text(product?.name ?? 'Sản phẩm không tồn tại',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                              'Giá: ${formatCurrency.format(detail.price)}'), // Giá lúc mua
                          trailing: Text('x ${detail.quantity}'),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),
                    const Divider(height: 32),

                    // --- Thanh toán ---
                    _buildSectionTitle(context, 'Thanh toán'),
                    order.paymentMethod == 0
                        ? _buildInfoRow(
                            'Phương thức:', 'Thanh toán khi nhận hàng (COD)')
                        : _buildInfoRow(
                            'Phương thức:', 'Thanh toán online (VNPay)'),
                    const Divider(height: 32),

                    // --- Tổng kết ---
                    _buildTotalRow(
                        'Tổng tiền hàng:', formatCurrency.format(subtotal)),
                    _buildTotalRow(
                        'Phí vận chuyển:', formatCurrency.format(shippingFee)),
                    const SizedBox(height: 8),
                    _buildTotalRow(
                        'Tổng cộng:', formatCurrency.format(order.total),
                        isTotal: true), // Tổng cuối cùng

                    // --- (Optional) Các nút hành động ---
                    // Ví dụ: Nút mua lại, nút đánh giá (nếu status=3)
                    const SizedBox(height: 24),
                    // if (order.status == 3)
                    //    Center(child: ElevatedButton(onPressed: (){}, child: Text('Viết đánh giá')))
                    // else if (order.status != 4) // Nếu chưa hủy
                    //    Center(child: OutlinedButton(onPressed: (){}, child: Text('Mua lại')))
                  ],
                ),
              );
            }
            return const SizedBox.shrink(); // Các trạng thái khác
          },
        ),
      ),
    );
  }

  // Helper widget cho tiêu đề section
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  // Helper widget cho một dòng thông tin (Label: Value)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Helper widget cho dòng tổng kết
  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
