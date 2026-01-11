// lib/blocs/client/credit_order_history/credit_order_history_state.dart
part of 'credit_order_history_bloc.dart';

abstract class CreditOrderHistoryState extends Equatable {
  const CreditOrderHistoryState();
  @override
  List<Object> get props => [];
}

class CreditOrderHistoryInitial extends CreditOrderHistoryState {}

class CreditOrderHistoryLoading extends CreditOrderHistoryState {
  final List<CreditOrderModel>? previousOrders; // Thêm dòng này
  const CreditOrderHistoryLoading(
      {this.previousOrders}); // Cập nhật constructor

  @override
  List<Object> get props => [previousOrders ?? []]; // Cập nhật props
}

class CreditOrderHistoryLoaded extends CreditOrderHistoryState {
  final List<CreditOrderModel> orders;
  const CreditOrderHistoryLoaded(this.orders);
  @override
  List<Object> get props => [orders];
}

class CreditOrderHistoryEmpty extends CreditOrderHistoryState {}

class CreditOrderHistoryError extends CreditOrderHistoryState {
  final String message;
  const CreditOrderHistoryError(this.message);
  @override
  List<Object> get props => [message];
}
