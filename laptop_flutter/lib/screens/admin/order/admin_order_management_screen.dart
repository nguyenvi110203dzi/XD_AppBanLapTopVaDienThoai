import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Cần import intl

import '../../../blocs/admin_management/order_management/admin_order_bloc.dart';
import '../../../blocs/admin_management/order_management/admin_order_detail_bloc.dart';
import '../../../models/order.dart';
import '../../../repositories/order_repository.dart';
import '../../../widgets/order_list_item.dart';
import 'admin_order_detail_screen.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang giao',
    'Đã giao',
    'Đã hủy'
  ];
  // Mapping từ tab index sang status number (hoặc null cho 'Tất cả')
  final List<int?> _tabStatusMapping = [null, 0, 1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      // Chỉ dispatch event khi tab thực sự được chọn xong
      if (!_tabController.indexIsChanging && mounted) {
        // Thêm kiểm tra mounted
        final selectedStatus = _tabStatusMapping[_tabController.index];
        context
            .read<AdminOrderBloc>()
            .add(FilterAdminOrdersByStatus(status: selectedStatus));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Hàm helper để lấy màu và chữ trạng thái (có thể đưa vào utils)
  Map<String, dynamic> _getStatusInfo(int status) {
    switch (status) {
      case 0:
        return {'text': 'Chờ xác nhận', 'color': Colors.orange.shade700};
      case 1:
        return {'text': 'Đã xác nhận', 'color': Colors.blue.shade700};
      case 2:
        return {'text': 'Đang giao', 'color': Colors.purple.shade600};
      case 3:
        return {'text': 'Đã giao', 'color': Colors.green.shade700};
      case 4:
        return {'text': 'Đã hủy', 'color': Colors.red.shade700};
      default:
        return {'text': 'Không xác định', 'color': Colors.grey.shade600};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold và AppBar được cung cấp bởi AdminMainScreen
    return Column(
      children: [
        // TabBar
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((String title) => Tab(text: title)).toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellowAccent, // Màu vạch chân nổi bật hơn
            indicatorWeight: 3.0,
          ),
        ),
        // Nội dung danh sách
        Expanded(
          child: BlocBuilder<AdminOrderBloc, AdminOrderState>(
            builder: (context, state) {
              if (state is AdminOrderListLoading &&
                  state.previousFilteredOrders == null) {
                return const Center(child: CircularProgressIndicator());
              }
              // --- Xử lý Lỗi ---
              if (state is AdminOrderListLoadFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text('Lỗi tải đơn hàng: ${state.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          onPressed: () => context
                              .read<AdminOrderBloc>()
                              .add(LoadAllAdminOrders()),
                        )
                      ],
                    ),
                  ),
                );
              }

              // --- Xử lý khi có dữ liệu (Loaded hoặc Loading ngầm) ---
              List<OrderModel> ordersToShow = [];
              if (state is AdminOrderListLoaded) {
                ordersToShow = state.filteredOrders;
              }
              // Không cần trường hợp loading ngầm vì BlocBuilder sẽ nhận state Loaded mới nhất

              if (ordersToShow.isEmpty && state is! AdminOrderListLoading) {
                // Chỉ báo rỗng khi không loading
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _tabController.index == 0
                        ? 'Hiện chưa có đơn hàng nào.'
                        : 'Không có đơn hàng nào ở trạng thái "${_tabs[_tabController.index]}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ));
              }

              // --- Hiển thị danh sách ---
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<AdminOrderBloc>().add(LoadAllAdminOrders());
                  // Đợi một chút để Bloc có thời gian xử lý và emit state mới
                  await context.read<AdminOrderBloc>().stream.firstWhere((s) =>
                      s is AdminOrderListLoaded ||
                      s is AdminOrderListLoadFailure);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      top: 8.0, bottom: 8.0), // Thêm padding cho list
                  itemCount: ordersToShow.length,
                  itemBuilder: (context, index) {
                    final order = ordersToShow[index];
                    return OrderListItem(
                      order: order,
                      statusInfo: _getStatusInfo(order.status),
                      onTap: () {
                        // Điều hướng và cung cấp Bloc cho màn hình detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider<AdminOrderDetailBloc>(
                              create: (ctx) => AdminOrderDetailBloc(
                                // Tạo instance của Bloc
                                orderRepository:
                                    RepositoryProvider.of<OrderRepository>(
                                        context),
                              )..add(LoadAdminOrderDetail(order.id)),
                              child: AdminOrderDetailScreen(orderId: order.id),
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            print(
                                "[AdminOrderManagementScreen] Reloading list after detail screen action.");
                            context
                                .read<AdminOrderBloc>()
                                .add(LoadAllAdminOrders());
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
