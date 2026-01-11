part of 'order_detail_bloc.dart';

abstract class OrderDetailState extends Equatable {
  const OrderDetailState();
  @override
  List<Object> get props => [];
}

class OrderDetailLoading extends OrderDetailState {}

class OrderDetailLoaded extends OrderDetailState {
  final OrderModel order; // Giữ object Order hoàn chỉnh
  const OrderDetailLoaded(this.order);
  @override
  List<Object> get props => [order];
}

class OrderDetailError extends OrderDetailState {
  final String message;
  const OrderDetailError(this.message);
  @override
  List<Object> get props => [message];
}
