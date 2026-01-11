part of 'warehouse_management_bloc.dart'; // QUAN TRỌNG

abstract class WarehouseManagementState extends Equatable {
  const WarehouseManagementState();
  @override
  List<Object?> get props => [];
}

class WarehouseInitial extends WarehouseManagementState {}

class WarehouseLoading extends WarehouseManagementState {}

class WarehouseOperationSuccess extends WarehouseManagementState {
  final ProductModel product; // Sản phẩm đã được cập nhật số lượng
  final String message;
  const WarehouseOperationSuccess(this.product, this.message);
  @override
  List<Object?> get props => [product, message];
}

class WarehouseHistoryLoaded extends WarehouseManagementState {
  final List<InventoryTransactionModel> history;
  final String productName;
  const WarehouseHistoryLoaded(this.history, this.productName);
  @override
  List<Object?> get props => [history, productName];
}

class WarehouseFailure extends WarehouseManagementState {
  final String error;
  const WarehouseFailure(this.error);
  @override
  List<Object> get props => [error];
}
