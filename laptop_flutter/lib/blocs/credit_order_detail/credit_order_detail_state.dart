part of 'credit_order_detail_bloc.dart';

abstract class CreditOrderDetailState extends Equatable {
  const CreditOrderDetailState();
  @override
  List<Object> get props => [];
}

class CreditOrderDetailInitial extends CreditOrderDetailState {}

class CreditOrderDetailLoading extends CreditOrderDetailState {}

class CreditOrderDetailLoaded extends CreditOrderDetailState {
  final CreditOrderModel order;
  const CreditOrderDetailLoaded(this.order);
  @override
  List<Object> get props => [order];
}

class CreditOrderDetailError extends CreditOrderDetailState {
  final String message;
  const CreditOrderDetailError(this.message);
  @override
  List<Object> get props => [message];
}
