part of 'order_detail_bloc.dart';

abstract class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();
  @override
  List<Object> get props => [];
}

class LoadOrderDetail extends OrderDetailEvent {
  final int orderId;
  const LoadOrderDetail(this.orderId);
  @override
  List<Object> get props => [orderId];
}
