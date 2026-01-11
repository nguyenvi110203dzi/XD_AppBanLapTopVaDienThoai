import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

part 'admin_credit_order_event.dart';
part 'admin_credit_order_state.dart';

class AdminCreditOrderBloc
    extends Bloc<AdminCreditOrderEvent, AdminCreditOrderState> {
  final CreditOrderRepository _creditOrderRepository;
  List<CreditOrderModel> _allOrdersCache = [];

  AdminCreditOrderBloc({required CreditOrderRepository creditOrderRepository})
      : _creditOrderRepository = creditOrderRepository,
        super(AdminCreditOrderInitial()) {
    on<LoadAllAdminCreditOrders>(_onLoadAllAdminCreditOrders);
    on<FilterAdminCreditOrdersByStatus>(_onFilterAdminCreditOrdersByStatus);
  }

  String get baseUrl => _creditOrderRepository.authRepository.baseUrl;

  Future<void> _onLoadAllAdminCreditOrders(
    LoadAllAdminCreditOrders event,
    Emitter<AdminCreditOrderState> emit,
  ) async {
    // Giữ lại danh sách đang lọc hiện tại để hiển thị tạm thời khi loading
    List<CreditOrderModel>? previousFiltered;
    int? currentStatus;
    int? currentUserId;

    if (state is AdminCreditOrderListLoaded) {
      final loadedState = state as AdminCreditOrderListLoaded;
      previousFiltered = loadedState.filteredOrders;
      currentStatus = loadedState.currentStatusFilter;
      currentUserId = loadedState.currentUserIdFilter;
    } else if (state is AdminCreditOrderListLoading) {
      final loadingState = state as AdminCreditOrderListLoading;
      previousFiltered = loadingState.previousFilteredOrders;
      // Không có currentStatus, currentUserId ở đây vì chưa load xong
    }

    emit(AdminCreditOrderListLoading(previousFilteredOrders: previousFiltered));
    try {
      final orders = await _creditOrderRepository.getAllCreditOrdersForAdmin();
      _allOrdersCache = orders;

      // Áp dụng lại filter cũ (nếu có) sau khi tải lại toàn bộ danh sách
      List<CreditOrderModel> newlyFilteredOrders = orders;
      if (currentStatus != null || currentUserId != null) {
        newlyFilteredOrders =
            _filterOrders(orders, currentStatus, currentUserId);
      }

      emit(AdminCreditOrderListLoaded(
        allOrders: orders,
        filteredOrders: newlyFilteredOrders,
        currentStatusFilter: currentStatus,
        currentUserIdFilter: currentUserId,
      ));
    } catch (e) {
      emit(AdminCreditOrderListLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  List<CreditOrderModel> _filterOrders(
      List<CreditOrderModel> orders, int? status, int? userId) {
    return orders.where((order) {
      final statusMatch = (status == null) || (order.status == status);
      final userMatch = (userId == null) || (order.userId == userId);
      return statusMatch && userMatch;
    }).toList();
  }

  void _onFilterAdminCreditOrdersByStatus(
    FilterAdminCreditOrdersByStatus event,
    Emitter<AdminCreditOrderState> emit,
  ) {
    if (state is AdminCreditOrderListLoaded || _allOrdersCache.isNotEmpty) {
      final List<CreditOrderModel> sourceOrders =
          (state is AdminCreditOrderListLoaded)
              ? (state as AdminCreditOrderListLoaded).allOrders
              : _allOrdersCache;

      final filtered = _filterOrders(sourceOrders, event.status, event.userId);

      emit(AdminCreditOrderListLoaded(
        allOrders: sourceOrders, // Luôn là danh sách gốc từ cache
        filteredOrders: filtered,
        currentStatusFilter: event.status,
        currentUserIdFilter: event.userId,
      ));
    } else if (state is AdminCreditOrderListLoading &&
        (state as AdminCreditOrderListLoading).previousFilteredOrders != null) {
      // Trường hợp đang loading mà người dùng filter -> filter trên previous data
      final previousOrders =
          (state as AdminCreditOrderListLoading).previousFilteredOrders!;
      final filtered =
          _filterOrders(previousOrders, event.status, event.userId);
      emit(AdminCreditOrderListLoaded(
        // Chuyển sang loaded với dữ liệu đã filter
        allOrders: previousOrders, // hoặc allOrdersCache nếu nó không rỗng
        filteredOrders: filtered,
        currentStatusFilter: event.status,
        currentUserIdFilter: event.userId,
      ));
    }
    // Nếu không có dữ liệu (ví dụ: đang initial loading), không làm gì cả, chờ LoadAllAdminCreditOrders hoàn thành.
  }
}
