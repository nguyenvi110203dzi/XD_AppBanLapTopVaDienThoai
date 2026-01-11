part of 'admin_order_detail_bloc.dart';

abstract class AdminOrderDetailEvent extends Equatable {
  const AdminOrderDetailEvent();

  @override
  List<Object> get props => [];
}

// Event để tải chi tiết một đơn hàng cụ thể
class LoadAdminOrderDetail extends AdminOrderDetailEvent {
  final int orderId;

  const LoadAdminOrderDetail(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Event để cập nhật trạng thái đơn hàng
class UpdateAdminOrderStatus extends AdminOrderDetailEvent {
  final int orderId;
  final int newStatus;

  const UpdateAdminOrderStatus(
      {required this.orderId, required this.newStatus});

  @override
  List<Object> get props => [orderId, newStatus];
}

// Event để xóa đơn hàng
class DeleteAdminOrder extends AdminOrderDetailEvent {
  final int orderId;

  const DeleteAdminOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}
