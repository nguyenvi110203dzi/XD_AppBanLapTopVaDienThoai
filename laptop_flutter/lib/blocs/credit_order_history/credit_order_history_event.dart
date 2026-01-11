part of 'credit_order_history_bloc.dart';

abstract class CreditOrderHistoryEvent extends Equatable {
  const CreditOrderHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadMyCreditOrders extends CreditOrderHistoryEvent {
  final int? statusFilter;
  const LoadMyCreditOrders({this.statusFilter});
  @override
  List<Object?> get props => [statusFilter];
}
