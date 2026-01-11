part of 'order_history_bloc.dart';

abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderHistoryEvent {
  final int? statusFilter; // Trạng thái cần lọc (null = tất cả)
  const LoadOrders({this.statusFilter});
  @override
  List<Object?> get props => [statusFilter];
}
