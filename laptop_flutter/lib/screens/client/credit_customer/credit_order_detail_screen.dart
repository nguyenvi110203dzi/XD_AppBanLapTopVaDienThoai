// lib/screens/client/credit_customer/credit_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laptop_flutter/blocs/credit_order_detail/credit_order_detail_bloc.dart';
import 'package:laptop_flutter/config/app_constants.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

class CreditOrderDetailScreen extends StatelessWidget {
  final int orderId;

  const CreditOrderDetailScreen({super.key, required this.orderId});

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'Chờ thanh toán';
      case 1:
        return 'Đã thanh toán';
      case 2:
        return 'Quá hạn';
      case 3:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(int status, BuildContext context) {
    switch (status) {
      case 0:
        return Colors.orange.shade700;
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.red.shade700;
      case 3:
        return Colors.grey.shade600;
      default:
        return Theme.of(context).disabledColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final formatDate = DateFormat('dd/MM/yyyy HH:mm');
    final formatDateOnly = DateFormat('dd/MM/yyyy');

    return BlocProvider(
      create: (context) => CreditOrderDetailBloc(
        creditOrderRepository: context.read<CreditOrderRepository>(),
      )..add(LoadMyCreditOrderDetail(orderId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chi Tiết Đơn Công Nợ #$orderId'),
        ),
        body: BlocBuilder<CreditOrderDetailBloc, CreditOrderDetailState>(
          builder: (context, state) {
            if (state is CreditOrderDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CreditOrderDetailError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is CreditOrderDetailLoaded) {
              final order = state.order;
              final details = order.creditOrderDetails ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Thông tin chung',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Divider(),
                            _buildInfoRow('Mã đơn:', '#${order.id}'),
                            _buildInfoRow('Ngày đặt:',
                                formatDate.format(order.orderDate)),
                            if (order.user != null) ...[
                              _buildInfoRow('Khách hàng:', order.user!.name),
                              _buildInfoRow('Email:', order.user!.email),
                              _buildInfoRow(
                                  'SĐT:', order.user!.phone ?? 'Chưa có'),
                            ],
                            Row(
                              children: [
                                const Text('Trạng thái: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  _getStatusText(order.status),
                                  style: TextStyle(
                                      color: _getStatusColor(
                                          order.status, context),
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            _buildInfoRow(
                              'Ngày hẹn trả:',
                              order.dueDate != null
                                  ? formatDateOnly.format(order.dueDate!)
                                  : 'Chưa có',
                              valueColor: order.dueDate != null &&
                                      order.dueDate!.isBefore(DateTime.now()) &&
                                      order.status == 0
                                  ? Colors.red
                                  : null,
                            ),
                            if (order.paymentDate != null)
                              _buildInfoRow('Ngày thanh toán:',
                                  formatDate.format(order.paymentDate!)),
                            _buildInfoRow('Ghi chú:', order.note ?? 'Không có'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Chi tiết sản phẩm (${details.length}):',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (details.isEmpty)
                      const Text('Không có sản phẩm trong đơn hàng này.')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: details.length,
                        itemBuilder: (context, index) {
                          final detail = details[index];
                          final product = detail.product;
                          return Card(
                            elevation: 1,
                            child: ListTile(
                              leading: product?.image != null
                                  ? Image.network(
                                      AppConstants.baseUrl + product!.image!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported,
                                      size: 50),
                              title: Text(
                                  product?.name ?? 'Sản phẩm không xác định'),
                              subtitle: Text(
                                  'SL: ${detail.quantity} - Giá: ${formatCurrency.format(detail.price)}'),
                              trailing: Text(formatCurrency
                                  .format(detail.quantity * detail.price)),
                            ),
                          );
                        },
                        separatorBuilder: (ctx, idx) =>
                            const SizedBox(height: 6),
                      ),
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Tổng tiền: ${formatCurrency.format(order.total)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange),
                      ),
                    ),
                    // TODO: Có thể thêm nút "Yêu cầu hỗ trợ", "Thanh toán ngay" (nếu status là chờ TT và có cổng TT)
                  ],
                ),
              );
            }
            return const Center(child: Text('Đang tải chi tiết...'));
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}
