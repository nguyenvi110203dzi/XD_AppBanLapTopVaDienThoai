import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import Models và Repositories cần thiết
import '../../../models/order.dart';
import '../../../repositories/order_repository.dart'; // Giả sử bạn đã có và cập nhật repo này

part 'admin_order_event.dart'; // Liên kết với file event
part 'admin_order_state.dart'; // Liên kết với file state

class AdminOrderBloc extends Bloc<AdminOrderEvent, AdminOrderState> {
  final OrderRepository _orderRepository;
  List<OrderModel> _allOrdersCache = []; // Cache danh sách đơn hàng gốc

  // Constructor nhận OrderRepository
  AdminOrderBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(AdminOrderInitial()) {
    // Trạng thái ban đầu

    // Đăng ký các bộ xử lý sự kiện
    on<LoadAllAdminOrders>(_onLoadAllAdminOrders);
    on<FilterAdminOrdersByStatus>(_onFilterAdminOrdersByStatus);
  }

  // --- Xử lý Event cho Danh sách đơn hàng ---

  Future<void> _onLoadAllAdminOrders(
      LoadAllAdminOrders event, Emitter<AdminOrderState> emit) async {
    List<OrderModel>? previousFiltered;
    if (state is AdminOrderListLoaded) {
      previousFiltered = (state as AdminOrderListLoaded).filteredOrders;
    } else if (state is AdminOrderListLoading &&
        (state as AdminOrderListLoading).previousFilteredOrders != null) {
      previousFiltered =
          (state as AdminOrderListLoading).previousFilteredOrders;
    }
    emit(AdminOrderListLoading(
        previousFilteredOrders: previousFiltered)); // Phát trạng thái đang tải
    try {
      // Gọi API lấy tất cả đơn hàng từ repository
      final orders = await _orderRepository.getAllOrders();
      _allOrdersCache = orders; // Lưu vào cache
      // Ban đầu, filtered list chính là all list
      emit(AdminOrderListLoaded(
          allOrders: orders,
          filteredOrders: orders,
          currentStatusFilter: null // Chưa có filter
          ));
    } catch (e) {
      emit(AdminOrderListLoadFailure(
          e.toString().replaceFirst('Exception: ', ''))); // Phát lỗi
    }
  }

  void _onFilterAdminOrdersByStatus(
      FilterAdminOrdersByStatus event, Emitter<AdminOrderState> emit) {
    // Chỉ lọc khi state hiện tại là Loaded
    if (state is AdminOrderListLoaded) {
      final currentState = state as AdminOrderListLoaded;
      List<OrderModel> filtered;
      if (event.status == null) {
        // Nếu status là null, hiển thị tất cả
        filtered = _allOrdersCache;
      } else {
        // Lọc từ cache danh sách gốc
        filtered = _allOrdersCache
            .where((order) => order.status == event.status)
            .toList();
      }
      // Emit state mới với danh sách đã lọc và filter hiện tại
      emit(currentState.copyWith(
          filteredOrders: filtered,
          currentStatusFilter: event.status,
          forceFilterUpdate: true // Cập nhật filter
          ));
    }
    // Nếu state không phải Loaded, có thể emit lỗi hoặc bỏ qua
  }

  // Helper để lấy baseUrl (nếu cần dùng trong UI hoặc nơi khác)
  String get baseUrl => _orderRepository.baseUrl;
}
