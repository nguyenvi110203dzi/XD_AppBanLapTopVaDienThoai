// lib/screens/client/credit_customer/credit_order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date and currency formatting
import 'package:laptop_flutter/blocs/credit_order_history/credit_order_history_bloc.dart';

import '../../../models/credit_order.dart';
import 'credit_order_detail_screen.dart'; // Sẽ tạo màn hình này

class CreditOrderHistoryScreen extends StatefulWidget {
  final int? initialStatusFilter;
  const CreditOrderHistoryScreen({super.key, this.initialStatusFilter});

  @override
  State<CreditOrderHistoryScreen> createState() =>
      _CreditOrderHistoryScreenState();
}

class _CreditOrderHistoryScreenState extends State<CreditOrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Tất cả', 'Chờ TT', 'Đã TT', 'Quá hạn', 'Đã hủy'];
  final List<int?> _tabStatusMapping = [
    null,
    0,
    1,
    2,
    3
  ]; // 0: Chờ, 1: Đã TT, 2: Quá hạn, 3: Hủy

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Xác định tab ban đầu dựa trên initialStatusFilter
    int initialIndex = 0;
    if (widget.initialStatusFilter != null) {
      initialIndex = _tabStatusMapping.indexOf(widget.initialStatusFilter);
      if (initialIndex == -1)
        initialIndex = 0; // Mặc định về tab "Tất cả" nếu không khớp
    }
    _tabController.index = initialIndex;

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        final selectedStatus = _tabStatusMapping[_tabController.index];
        context
            .read<CreditOrderHistoryBloc>()
            .add(LoadMyCreditOrders(statusFilter: selectedStatus));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final formatDate = DateFormat('dd/MM/yyyy HH:mm');
    List<CreditOrderModel> ordersToShow = [];
    bool showLoadingIndicator = false;

    return BlocProvider.value(
      // Sử dụng BlocProvider.value nếu Bloc đã được cung cấp từ cha (CreditCustomerMainScreen)
      // Nếu không, dùng BlocProvider.create
      value: context.read<CreditOrderHistoryBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch Sử Đơn Công Nợ'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((String title) => Tab(text: title)).toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellowAccent,
          ),
        ),
        body: BlocBuilder<CreditOrderHistoryBloc, CreditOrderHistoryState>(
          builder: (context, state) {
            if (state is CreditOrderHistoryLoading &&
                state is! CreditOrderHistoryLoaded) {
              // Chỉ loading toàn màn hình khi chưa có data
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CreditOrderHistoryLoaded) {
              ordersToShow = state.orders;
            } else if (state is CreditOrderHistoryLoading) {
              if (state.previousOrders != null &&
                  state.previousOrders!.isNotEmpty) {
                ordersToShow = state.previousOrders!;
                // Có thể hiển thị một indicator nhỏ ở trên cùng của list thay vì full screen
                showLoadingIndicator =
                    true; // Bạn có thể dùng cờ này để thêm 1 widget loading ở trên list
              } else {
                // Nếu không có previousOrders, đó là loading lần đầu
                return const Center(child: CircularProgressIndicator());
              }
            } else if (state is CreditOrderHistoryError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            } else if (state is CreditOrderHistoryEmpty) {
              return Center(
                  child: Text(
                      'Không có đơn hàng công nợ nào ${_tabController.index == 0 ? '' : 'ở trạng thái "${_tabs[_tabController.index]}"'}.'));
            }

            if (ordersToShow.isEmpty && !showLoadingIndicator) {
              // Nếu đã loaded mà rỗng, hoặc lỗi mà không có gì để hiển thị
              if (state is! CreditOrderHistoryLoading) {
                // Chỉ hiển thị "Không có đơn" khi không phải loading
                return Center(
                    child: Text(
                        'Không có đơn hàng công nợ nào ${_tabController.index == 0 ? '' : 'ở trạng thái "${_tabs[_tabController.index]}"'}.'));
              }
            }

            return Column(
              // Để có thể thêm loading indicator ở trên nếu cần
              children: [
                if (showLoadingIndicator)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.0)),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<CreditOrderHistoryBloc>().add(
                          LoadMyCreditOrders(
                              statusFilter:
                                  _tabStatusMapping[_tabController.index]));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: ordersToShow.length,
                      itemBuilder: (context, index) {
                        final order = ordersToShow[index];
                        // ... (Phần còn lại của ListTile như cũ)
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          elevation: 2,
                          child: ListTile(
                            title: Text(
                                'Đơn #${order.id} - ${formatCurrency.format(order.total)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Ngày đặt: ${formatDate.format(order.orderDate)}'),
                                Text('Ngày hẹn trả: ${order.dueDateFormatted}',
                                    style: TextStyle(
                                        color: order.dueDate != null &&
                                                order.dueDate!
                                                    .isBefore(DateTime.now()) &&
                                                order.status == 0
                                            ? Colors.red
                                            : null)),
                                if (order.paymentDate != null)
                                  Text(
                                      'Ngày thanh toán: ${order.paymentDateFormatted}'),
                                Text('Ghi chú: ${order.note ?? 'Không có'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(_getStatusText(order.status),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10)),
                              backgroundColor: _getStatusColor(order.status),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreditOrderDetailScreen(
                                      orderId: order.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
