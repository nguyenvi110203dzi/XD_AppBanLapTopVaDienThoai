part of 'admin_order_bloc.dart'; // Chỉ định file Bloc tương ứng

abstract class AdminOrderState extends Equatable {
  const AdminOrderState();

  @override
  List<Object?> get props => [];
}

// Trạng thái ban đầu / khởi tạo
class AdminOrderInitial extends AdminOrderState {}

// --- States cho danh sách đơn hàng ---

// Trạng thái đang tải danh sách đơn hàng
class AdminOrderListLoading extends AdminOrderState {
  final List<OrderModel>? previousFilteredOrders;
  const AdminOrderListLoading({this.previousFilteredOrders});
  @override
  List<Object?> get props => [previousFilteredOrders];
}

// Trạng thái tải danh sách đơn hàng thành công
class AdminOrderListLoaded extends AdminOrderState {
  final List<OrderModel> allOrders; // Lưu danh sách gốc
  final List<OrderModel> filteredOrders; // Danh sách đã lọc theo trạng thái
  final int? currentStatusFilter; // Trạng thái lọc hiện tại (null là tất cả)

  const AdminOrderListLoaded({
    required this.allOrders,
    required this.filteredOrders,
    this.currentStatusFilter,
  });

  @override
  List<Object?> get props => [allOrders, filteredOrders, currentStatusFilter];

  // Helper để tạo bản sao state với dữ liệu mới (khi lọc)
  AdminOrderListLoaded copyWith({
    List<OrderModel>? allOrders,
    List<OrderModel>? filteredOrders,
    int? currentStatusFilter, // Lưu ý: có thể là null
    bool forceFilterUpdate =
        false, // Đánh dấu để biết có cần cập nhật filter không
  }) {
    return AdminOrderListLoaded(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      // Nếu forceFilterUpdate là true, dùng giá trị mới, ngược lại giữ giá trị cũ
      currentStatusFilter:
          forceFilterUpdate ? currentStatusFilter : this.currentStatusFilter,
    );
  }
}

// Trạng thái tải danh sách đơn hàng thất bại
class AdminOrderListLoadFailure extends AdminOrderState {
  final String error;

  const AdminOrderListLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}
