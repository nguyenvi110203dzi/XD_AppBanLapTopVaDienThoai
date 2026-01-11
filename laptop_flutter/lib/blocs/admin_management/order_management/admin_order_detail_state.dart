part of 'admin_order_detail_bloc.dart';

abstract class AdminOrderDetailState extends Equatable {
  const AdminOrderDetailState();

  @override
  List<Object?> get props => [];
}

class AdminOrderDetailInitial extends AdminOrderDetailState {}

// Trạng thái đang tải chi tiết đơn hàng
class AdminOrderDetailLoading extends AdminOrderDetailState {}

// Trạng thái tải chi tiết đơn hàng thành công
class AdminOrderDetailLoaded extends AdminOrderDetailState {
  final OrderModel order;

  const AdminOrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

// Trạng thái tải chi tiết đơn hàng thất bại
class AdminOrderDetailLoadFailure extends AdminOrderDetailState {
  final String error;

  const AdminOrderDetailLoadFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Trạng thái đang cập nhật trạng thái đơn hàng
class AdminOrderStatusUpdating extends AdminOrderDetailState {
  final OrderModel order; // Giữ lại order hiện tại để hiển thị UI
  const AdminOrderStatusUpdating(this.order);
  @override
  List<Object?> get props => [order];
}

// Trạng thái cập nhật trạng thái thành công
class AdminOrderStatusUpdateSuccess extends AdminOrderDetailState {
  final OrderModel updatedOrder; // Trả về order đã cập nhật
  const AdminOrderStatusUpdateSuccess(this.updatedOrder);
  @override
  List<Object?> get props => [updatedOrder];
}

// Trạng thái cập nhật trạng thái thất bại
class AdminOrderStatusUpdateFailure extends AdminOrderDetailState {
  final String error;
  final OrderModel originalOrder; // Giữ lại order gốc
  const AdminOrderStatusUpdateFailure(this.error, this.originalOrder);
  @override
  List<Object?> get props => [error, originalOrder];
}

// Trạng thái đang xóa đơn hàng
class AdminOrderDeleting extends AdminOrderDetailState {
  final int orderId; // Giữ lại order để hiển thị UI khi loading
  const AdminOrderDeleting(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

// Trạng thái xóa đơn hàng thành công
class AdminOrderDeleteSuccess extends AdminOrderDetailState {}

// Trạng thái xóa đơn hàng thất bại
class AdminOrderDeleteFailure extends AdminOrderDetailState {
  final String error;
  final OrderModel originalOrder; // Giữ lại order gốc
  const AdminOrderDeleteFailure(this.error, this.originalOrder);
  @override
  List<Object?> get props => [error, originalOrder];
}
