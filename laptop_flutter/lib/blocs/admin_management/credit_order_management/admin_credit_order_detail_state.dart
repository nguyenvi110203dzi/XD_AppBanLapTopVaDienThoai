part of 'admin_credit_order_detail_bloc.dart';

abstract class AdminCreditOrderDetailState extends Equatable {
  const AdminCreditOrderDetailState();
  @override
  List<Object?> get props => [];
}

class AdminCreditOrderDetailInitial extends AdminCreditOrderDetailState {}

class AdminCreditOrderDetailLoading extends AdminCreditOrderDetailState {}

class AdminCreditOrderDetailLoaded extends AdminCreditOrderDetailState {
  final CreditOrderModel order;
  const AdminCreditOrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}

class AdminCreditOrderDetailLoadFailure extends AdminCreditOrderDetailState {
  final String error;
  const AdminCreditOrderDetailLoadFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// States cho việc cập nhật
class AdminCreditOrderUpdating extends AdminCreditOrderDetailState {
  final CreditOrderModel order; // Giữ lại order hiện tại để UI không bị trống
  const AdminCreditOrderUpdating(this.order);
  @override
  List<Object?> get props => [order];
}

class AdminCreditOrderUpdateSuccess extends AdminCreditOrderDetailState {
  final CreditOrderModel updatedOrder;
  const AdminCreditOrderUpdateSuccess(this.updatedOrder);
  @override
  List<Object?> get props => [updatedOrder];
}

class AdminCreditOrderUpdateFailure extends AdminCreditOrderDetailState {
  final String error;
  final CreditOrderModel originalOrder; // Giữ lại order gốc nếu update lỗi
  const AdminCreditOrderUpdateFailure(this.error, this.originalOrder);
  @override
  List<Object?> get props => [error, originalOrder];
}
