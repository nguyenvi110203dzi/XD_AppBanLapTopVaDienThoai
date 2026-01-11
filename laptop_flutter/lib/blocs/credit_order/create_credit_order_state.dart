part of 'create_credit_order_bloc.dart';

abstract class CreateCreditOrderState extends Equatable {
  const CreateCreditOrderState();

  @override
  List<Object> get props => [];
}

class CreateCreditOrderInitial extends CreateCreditOrderState {}

class CreateCreditOrderInProgress extends CreateCreditOrderState {}

class CreateCreditOrderSuccess extends CreateCreditOrderState {
  final CreditOrderModel order;
  const CreateCreditOrderSuccess(this.order);
  @override
  List<Object> get props => [order];
}

class CreateCreditOrderFailure extends CreateCreditOrderState {
  final String error;
  const CreateCreditOrderFailure(this.error);
  @override
  List<Object> get props => [error];
}
