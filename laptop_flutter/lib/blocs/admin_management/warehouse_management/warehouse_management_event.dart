part of 'warehouse_management_bloc.dart';

abstract class WarehouseManagementEvent extends Equatable {
  const WarehouseManagementEvent();
  @override
  List<Object?> get props => [];
}

class ImportStockEvent extends WarehouseManagementEvent {
  final int productId;
  final int quantity;
  final String? notes;

  const ImportStockEvent(
      {required this.productId, required this.quantity, this.notes});
  @override
  List<Object?> get props => [productId, quantity, notes];
}

class ExportStockEvent extends WarehouseManagementEvent {
  final int productId;
  final int quantity;
  final String reason;
  final String? notes;

  const ExportStockEvent({
    required this.productId,
    required this.quantity,
    required this.reason,
    this.notes,
  });
  @override
  List<Object?> get props => [productId, quantity, reason, notes];
}

class LoadProductStockHistoryEvent extends WarehouseManagementEvent {
  final int productId;
  const LoadProductStockHistoryEvent(this.productId);
  @override
  List<Object> get props => [productId];
}

class LoadOverallQuantityEvent extends WarehouseManagementEvent {}

class WarehouseOverallQuantityLoaded extends WarehouseManagementState {
  final int totalQuantity;
  const WarehouseOverallQuantityLoaded(this.totalQuantity);
  @override
  List<Object> get props => [totalQuantity];
}
