// lib/blocs/admin_management/warehouse_management/warehouse_management_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/inventory_transaction_model.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/repositories/warehouse_repository.dart';

part 'warehouse_management_event.dart';
part 'warehouse_management_state.dart';

class WarehouseManagementBloc
    extends Bloc<WarehouseManagementEvent, WarehouseManagementState> {
  final WarehouseRepository warehouseRepository;

  WarehouseManagementBloc({required this.warehouseRepository})
      : super(WarehouseInitial()) {
    on<ImportStockEvent>(_onImportStock);
    // VVV ĐẢM BẢO DÒNG NÀY TỒN TẠI VÀ ĐÚNG VVV
    on<ExportStockEvent>(
        _onExportStock); // << Đăng ký handler cho ExportStockEvent
    // ^^^-----------------------------------------^^^
    on<LoadProductStockHistoryEvent>(_onLoadProductStockHistory);
    on<LoadOverallQuantityEvent>(_onLoadOverallQuantity);
  }

  Future<void> _onImportStock(
      ImportStockEvent event, Emitter<WarehouseManagementState> emit) async {
    emit(WarehouseLoading());
    try {
      final updatedProduct = await warehouseRepository.importStock(
        productId: event.productId,
        quantity: event.quantity,
        notes: event.notes,
      );
      emit(WarehouseOperationSuccess(updatedProduct, 'Nhập kho thành công!'));
    } catch (e) {
      emit(WarehouseFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // VVV ĐẢM BẢO BẠN CÓ HÀM XỬ LÝ NÀY VVV
  Future<void> _onExportStock(
      ExportStockEvent event, Emitter<WarehouseManagementState> emit) async {
    emit(WarehouseLoading());
    try {
      final updatedProduct = await warehouseRepository.exportStock(
        productId: event.productId,
        quantity: event.quantity,
        reason: event.reason,
        notes: event.notes,
      );
      emit(WarehouseOperationSuccess(updatedProduct, 'Xuất kho thành công!'));
    } catch (e) {
      emit(WarehouseFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
  // ^^^-----------------------------------^^^

  Future<void> _onLoadProductStockHistory(LoadProductStockHistoryEvent event,
      Emitter<WarehouseManagementState> emit) async {
    // ... (code của bạn)
    emit(WarehouseLoading());
    try {
      final history =
          await warehouseRepository.getProductStockHistory(event.productId);
      // Cần lấy tên sản phẩm ở đây, hoặc truyền từ UI, hoặc để Repository trả về
      // Ví dụ tạm:
      ProductModel? product;
      try {
        // Giả sử bạn có cách lấy product từ productId, ví dụ qua ProductRepository
        // Hoặc bạn có thể đã load danh sách sản phẩm và tìm trong đó
      } catch (_) {}

      emit(WarehouseHistoryLoaded(
          history, product?.name ?? "Sản phẩm ID: ${event.productId}"));
    } catch (e) {
      emit(WarehouseFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadOverallQuantity(LoadOverallQuantityEvent event,
      Emitter<WarehouseManagementState> emit) async {
    // ... (code của bạn)
    emit(WarehouseLoading());
    try {
      final totalQuantity =
          await warehouseRepository.getOverallProductQuantity();
      emit(WarehouseOverallQuantityLoaded(totalQuantity));
    } catch (e) {
      emit(WarehouseFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
