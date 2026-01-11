part of 'credit_order_detail_bloc.dart';

abstract class CreditOrderDetailEvent extends Equatable {
  const CreditOrderDetailEvent();
  @override
  List<Object> get props => [];
}

class LoadMyCreditOrderDetail extends CreditOrderDetailEvent {
  final int orderId;
  const LoadMyCreditOrderDetail(this.orderId);
  @override
  List<Object> get props => [orderId];
}
