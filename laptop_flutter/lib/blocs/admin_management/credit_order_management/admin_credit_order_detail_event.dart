part of 'admin_credit_order_detail_bloc.dart';

abstract class AdminCreditOrderDetailEvent extends Equatable {
  const AdminCreditOrderDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminCreditOrderDetail extends AdminCreditOrderDetailEvent {
  final int orderId;
  const LoadAdminCreditOrderDetail(this.orderId);
  @override
  List<Object> get props => [orderId];
}

class UpdateAdminCreditOrder extends AdminCreditOrderDetailEvent {
  final int orderId;
  final int? newStatus;
  final DateTime? newDueDate;
  final String? newNote;

  const UpdateAdminCreditOrder({
    required this.orderId,
    this.newStatus,
    this.newDueDate,
    this.newNote,
  });

  @override
  List<Object?> get props => [orderId, newStatus, newDueDate, newNote];
}
