import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:laptop_flutter/blocs/admin_management/credit_order_management/admin_credit_order_bloc.dart';
import 'package:laptop_flutter/blocs/admin_management/credit_order_management/admin_credit_order_detail_bloc.dart'; // Sẽ tạo
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';
import 'package:laptop_flutter/widgets/order_list_item.dart'; // Có thể tái sử dụng hoặc tạo CreditOrderListItem

import 'admin_credit_order_detail_screen.dart'; // Sẽ tạo

class AdminCreditOrderManagementScreen extends StatefulWidget {
  const AdminCreditOrderManagementScreen({super.key});

  @override
  State<AdminCreditOrderManagementScreen> createState() =>
      _AdminCreditOrderManagementScreenState();
}

class _AdminCreditOrderManagementScreenState
    extends State<AdminCreditOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Trạng thái của đơn hàng công nợ: 0: Chờ TT, 1: Đã TT, 2: Quá hạn, 3: Đã hủy
  final List<String> _tabs = ['Tất cả', 'Chờ TT', 'Đã TT', 'Quá hạn', 'Đã hủy'];
  final List<int?> _tabStatusMapping = [null, 0, 1, 2, 3];

  // TODO: Thêm bộ lọc theo User ID nếu cần
  // final TextEditingController _userIdFilterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Không cần load ở đây nữa vì đã load khi tạo Bloc trong AdminMainScreen
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        final selectedStatus = _tabStatusMapping[_tabController.index];
        context
            .read<AdminCreditOrderBloc>()
            .add(FilterAdminCreditOrdersByStatus(status: selectedStatus));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // _userIdFilterController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getStatusInfo(int status) {
    switch (status) {
      case 0:
        return {'text': 'Chờ thanh toán', 'color': Colors.orange.shade700};
      case 1:
        return {'text': 'Đã thanh toán', 'color': Colors.green.shade700};
      case 2:
        return {'text': 'Quá hạn', 'color': Colors.red.shade800};
      case 3:
        return {'text': 'Đã hủy', 'color': Colors.grey.shade600};
      default:
        return {'text': 'Không xác định', 'color': Colors.blueGrey.shade400};
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Column(
      children: [
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor ??
              Theme.of(context).primaryColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((String title) => Tab(text: title)).toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellowAccent,
            indicatorWeight: 3.0,
          ),
        ),
        // TODO: Thêm ô nhập liệu để filter theo User ID nếu muốn
        Expanded(
          child: BlocBuilder<AdminCreditOrderBloc, AdminCreditOrderState>(
            builder: (context, state) {
              if (state is AdminCreditOrderListLoading &&
                  state.previousFilteredOrders == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AdminCreditOrderListLoadFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text('Lỗi tải đơn công nợ: ${state.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                          onPressed: () => context
                              .read<AdminCreditOrderBloc>()
                              .add(const LoadAllAdminCreditOrders(
                                  forceRefresh: true)),
                        )
                      ],
                    ),
                  ),
                );
              }

              List<CreditOrderModel> ordersToShow = [];
              if (state is AdminCreditOrderListLoaded) {
                ordersToShow = state.filteredOrders;
              } else if (state is AdminCreditOrderListLoading &&
                  state.previousFilteredOrders != null) {
                ordersToShow = state.previousFilteredOrders!;
              }

              if (ordersToShow.isEmpty &&
                  state is! AdminCreditOrderListLoading) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _tabController.index == 0
                        ? 'Hiện chưa có đơn hàng công nợ nào.'
                        : 'Không có đơn hàng công nợ nào ở trạng thái "${_tabs[_tabController.index]}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ));
              }
              if (ordersToShow.isEmpty &&
                  state is AdminCreditOrderListLoading &&
                  state.previousFilteredOrders == null) {
                return const Center(
                    child:
                        CircularProgressIndicator()); // Vẫn đang loading lần đầu
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<AdminCreditOrderBloc>()
                      .add(const LoadAllAdminCreditOrders(forceRefresh: true));
                  await context.read<AdminCreditOrderBloc>().stream.firstWhere(
                      (s) =>
                          s is AdminCreditOrderListLoaded ||
                          s is AdminCreditOrderListLoadFailure);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: ordersToShow.length,
                  itemBuilder: (context, index) {
                    final order = ordersToShow[index];
                    final statusInfo = _getStatusInfo(order.status);
                    return Card(
                      // Tùy biến Card này cho CreditOrder
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      elevation: 1.5,
                      child: ListTile(
                        title: Text(
                            'Đơn #${order.id} - KH: ${order.user?.name ?? "N/A"}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Ngày đặt: ${DateFormat('dd/MM/yy HH:mm').format(order.orderDate.toLocal())}'),
                            Text('Ngày hẹn trả: ${order.dueDateFormatted}',
                                style: TextStyle(
                                    color: order.dueDate != null &&
                                            order.dueDate!
                                                .isBefore(DateTime.now()) &&
                                            order.status == 0
                                        ? Colors.red.shade700
                                        : null,
                                    fontWeight: order.dueDate != null &&
                                            order.dueDate!
                                                .isBefore(DateTime.now()) &&
                                            order.status == 0
                                        ? FontWeight.bold
                                        : null)),
                            Text('Tổng: ${formatCurrency.format(order.total)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(statusInfo['text'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500)),
                          backgroundColor: statusInfo['color'],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BlocProvider<AdminCreditOrderDetailBloc>(
                                // Sẽ tạo Bloc này
                                create: (ctx) => AdminCreditOrderDetailBloc(
                                  creditOrderRepository: RepositoryProvider.of<
                                      CreditOrderRepository>(context),
                                )..add(LoadAdminCreditOrderDetail(
                                    order.id)), // Load chi tiết
                                child: AdminCreditOrderDetailScreen(
                                    orderId: order.id), // Sẽ tạo màn hình này
                              ),
                            ),
                          ).then((result) {
                            // Xử lý sau khi pop từ màn hình chi tiết
                            if (result == true) {
                              // Nếu có thay đổi và cần load lại list
                              context.read<AdminCreditOrderBloc>().add(
                                  const LoadAllAdminCreditOrders(
                                      forceRefresh: true));
                            }
                          });
                        },
                      ),
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
