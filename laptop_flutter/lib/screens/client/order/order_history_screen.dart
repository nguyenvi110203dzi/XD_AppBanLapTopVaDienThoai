import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/order_history/order_history_bloc.dart';
import '../../../repositories/order_repository.dart';
import '../../../widgets/order_item_card.dart';
import 'order_detail_screen.dart';

// Import OrderDetailScreen nếu có
// import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  final int?
      initialStatusFilter; // Nhận bộ lọc trạng thái ban đầu (có thể null)

  const OrderHistoryScreen({super.key, this.initialStatusFilter});

  // Helper để lấy title dựa vào filter
  String _getTitle(int? filter) {
    switch (filter) {
      case 0:
        return 'Đơn hàng Chờ xác nhận';
      case 1:
        return 'Đơn hàng Chờ lấy hàng';
      case 2:
        return 'Đơn hàng Đang giao';
      case 3:
        return 'Đơn hàng Đã giao';
      case 4:
        return 'Đơn hàng Đã hủy'; // Có thể thêm filter này nếu muốn
      default:
        return 'Lịch sử mua hàng'; // Khi filter là null (tất cả)
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Cung cấp OrderHistoryBloc cục bộ cho màn hình này
      create: (context) => OrderHistoryBloc(
        orderRepository: context.read<OrderRepository>(), // Lấy repo từ context
      )..add(LoadOrders(
          statusFilter:
              initialStatusFilter)), // Load đơn hàng với filter ban đầu ngay khi tạo
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(initialStatusFilter)), // Hiển thị title phù hợp
          // TODO: Thêm TabBar hoặc Dropdown để người dùng tự đổi filter nếu muốn
        ),
        body: BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
          builder: (context, state) {
            if (state is OrderHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderHistoryError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Lỗi tải lịch sử đơn hàng: ${state.message}',
                    textAlign: TextAlign.center),
              ));
            }
            if (state is OrderHistoryEmpty) {
              return const Center(child: Text('Không có đơn hàng nào.'));
            }
            if (state is OrderHistoryLoaded) {
              // Hiển thị danh sách đơn hàng đã lọc
              return RefreshIndicator(
                // Thêm RefreshIndicator
                onRefresh: () async {
                  context
                      .read<OrderHistoryBloc>()
                      .add(LoadOrders(statusFilter: initialStatusFilter));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return OrderItemCard(
                      order: order,
                      onTap: () {
                        // TODO: Điều hướng đến chi tiết đơn hàng
                        print('Navigate to Order Detail: ${order.id}');
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailScreen(orderId: order.id)));
                      },
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink(); // Trạng thái khác (Initial)
          },
        ),
      ),
    );
  }
}
