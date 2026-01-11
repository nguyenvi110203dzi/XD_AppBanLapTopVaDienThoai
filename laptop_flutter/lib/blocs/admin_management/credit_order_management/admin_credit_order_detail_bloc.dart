import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

part 'admin_credit_order_detail_event.dart';
part 'admin_credit_order_detail_state.dart';

class AdminCreditOrderDetailBloc
    extends Bloc<AdminCreditOrderDetailEvent, AdminCreditOrderDetailState> {
  final CreditOrderRepository _creditOrderRepository;

  AdminCreditOrderDetailBloc(
      {required CreditOrderRepository creditOrderRepository})
      : _creditOrderRepository = creditOrderRepository,
        super(AdminCreditOrderDetailInitial()) {
    on<LoadAdminCreditOrderDetail>(_onLoadAdminCreditOrderDetail);
    on<UpdateAdminCreditOrder>(_onUpdateAdminCreditOrder);
  }

  String get baseUrl => _creditOrderRepository.authRepository.baseUrl;

  Future<void> _onLoadAdminCreditOrderDetail(
    LoadAdminCreditOrderDetail event,
    Emitter<AdminCreditOrderDetailState> emit,
  ) async {
    emit(AdminCreditOrderDetailLoading());
    try {
      final order = await _creditOrderRepository
          .getCreditOrderDetailForAdmin(event.orderId);
      emit(AdminCreditOrderDetailLoaded(order));
    } catch (e) {
      emit(AdminCreditOrderDetailLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onUpdateAdminCreditOrder(
    UpdateAdminCreditOrder event,
    Emitter<AdminCreditOrderDetailState> emit,
  ) async {
    CreditOrderModel? currentOrder;
    if (state is AdminCreditOrderDetailLoaded) {
      currentOrder = (state as AdminCreditOrderDetailLoaded).order;
    } else if (state is AdminCreditOrderUpdateFailure) {
      currentOrder = (state as AdminCreditOrderUpdateFailure).originalOrder;
    } else if (state is AdminCreditOrderUpdating) {
      return; // Đang cập nhật rồi, không làm gì thêm
    }

    if (currentOrder == null || currentOrder.id != event.orderId) {
      emit(const AdminCreditOrderDetailLoadFailure(
          "Không thể xác định đơn hàng để cập nhật."));
      return;
    }
    // Chỉ emit updating nếu có thay đổi thực sự so với trạng thái hiện tại của đơn hàng
    bool hasChanges = event.newStatus != null &&
            event.newStatus != currentOrder.status ||
        event.newDueDate != null && event.newDueDate != currentOrder.dueDate ||
        event.newNote != null && event.newNote != currentOrder.note;

    if (!hasChanges) {
      // Không có gì thay đổi, có thể emit lại state loaded hoặc không làm gì cả
      // emit(AdminCreditOrderDetailLoaded(currentOrder));
      return;
    }

    emit(AdminCreditOrderUpdating(currentOrder));
    try {
      final updatedOrder =
          await _creditOrderRepository.updateCreditOrderStatusForAdmin(
        orderId: event.orderId,
        status: event.newStatus,
        dueDate: event.newDueDate,
        note: event.newNote,
      );
      emit(AdminCreditOrderUpdateSuccess(updatedOrder));
    } catch (e) {
      emit(AdminCreditOrderUpdateFailure(
          e.toString().replaceFirst('Exception: ', ''), currentOrder));
    }
  }
}
