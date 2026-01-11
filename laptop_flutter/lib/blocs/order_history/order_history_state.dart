part of 'order_history_bloc.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();
  @override
  List<Object> get props => [];
}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderModel> orders; // << Danh sách đơn hàng đã được lọc
  const OrderHistoryLoaded(this.orders);
  @override
  List<Object> get props => [orders];
}

class OrderHistoryEmpty extends OrderHistoryState {}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  const OrderHistoryError(this.message);
  @override
  List<Object> get props => [message];
}
