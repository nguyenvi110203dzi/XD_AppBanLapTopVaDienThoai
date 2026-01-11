part of 'admin_credit_order_bloc.dart';

abstract class AdminCreditOrderState extends Equatable {
  const AdminCreditOrderState();

  @override
  List<Object?> get props => [];
}

class AdminCreditOrderInitial extends AdminCreditOrderState {}

class AdminCreditOrderListLoading extends AdminCreditOrderState {
  final List<CreditOrderModel>? previousFilteredOrders;
  const AdminCreditOrderListLoading({this.previousFilteredOrders});
  @override
  List<Object?> get props => [previousFilteredOrders];
}

class AdminCreditOrderListLoaded extends AdminCreditOrderState {
  final List<CreditOrderModel> allOrders;
  final List<CreditOrderModel> filteredOrders;
  final int? currentStatusFilter;
  final int? currentUserIdFilter;

  const AdminCreditOrderListLoaded({
    required this.allOrders,
    required this.filteredOrders,
    this.currentStatusFilter,
    this.currentUserIdFilter,
  });

  @override
  List<Object?> get props =>
      [allOrders, filteredOrders, currentStatusFilter, currentUserIdFilter];

  AdminCreditOrderListLoaded copyWith({
    List<CreditOrderModel>? allOrders,
    List<CreditOrderModel>? filteredOrders,
    int? currentStatusFilter,
    bool forceStatusFilterUpdate = false,
    int? currentUserIdFilter,
    bool forceUserIdFilterUpdate = false,
  }) {
    return AdminCreditOrderListLoaded(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      currentStatusFilter: forceStatusFilterUpdate
          ? currentStatusFilter
          : this.currentStatusFilter,
      currentUserIdFilter: forceUserIdFilterUpdate
          ? currentUserIdFilter
          : this.currentUserIdFilter,
    );
  }
}

class AdminCreditOrderListLoadFailure extends AdminCreditOrderState {
  final String error;
  const AdminCreditOrderListLoadFailure(this.error);
  @override
  List<Object?> get props => [error];
}
