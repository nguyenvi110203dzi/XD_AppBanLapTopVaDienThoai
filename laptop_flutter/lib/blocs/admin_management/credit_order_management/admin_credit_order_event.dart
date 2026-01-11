part of 'admin_credit_order_bloc.dart';

abstract class AdminCreditOrderEvent extends Equatable {
  const AdminCreditOrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllAdminCreditOrders extends AdminCreditOrderEvent {
  final bool forceRefresh; // Để bỏ qua cache nếu cần
  const LoadAllAdminCreditOrders({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class FilterAdminCreditOrdersByStatus extends AdminCreditOrderEvent {
  final int? status; // null nghĩa là hiển thị tất cả
  final int? userId; // Thêm filter theo userId nếu cần

  const FilterAdminCreditOrdersByStatus({this.status, this.userId});

  @override
  List<Object?> get props => [status, userId];
}
