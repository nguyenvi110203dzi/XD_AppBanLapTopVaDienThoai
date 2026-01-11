part of 'admin_order_bloc.dart'; // Chỉ định file Bloc tương ứng

abstract class AdminOrderEvent extends Equatable {
  const AdminOrderEvent();

  @override
  List<Object?> get props => [];
}

// Event để tải tất cả đơn hàng ban đầu cho Admin
class LoadAllAdminOrders extends AdminOrderEvent {}

// Event để lọc danh sách đơn hàng theo trạng thái
class FilterAdminOrdersByStatus extends AdminOrderEvent {
  final int? status; // null nghĩa là hiển thị tất cả

  const FilterAdminOrdersByStatus({this.status});

  @override
  List<Object?> get props => [status];
}
