import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/order.dart';
import '../../repositories/order_repository.dart';

part 'order_history_event.dart';
part 'order_history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final OrderRepository orderRepository;

  OrderHistoryBloc({required this.orderRepository})
      : super(OrderHistoryLoading()) {
    on<LoadOrders>(_onLoadOrders);
  }

  Future<void> _onLoadOrders(
      LoadOrders event, Emitter<OrderHistoryState> emit) async {
    emit(OrderHistoryLoading());
    try {
      // Gọi repo để lấy TẤT CẢ đơn hàng
      final List<OrderModel> allOrders =
          await orderRepository.getMyOrders(); // Luôn lấy tất cả

      // --- LỌC ở Frontend (Trong Bloc) ---
      final List<OrderModel> filteredOrders;
      if (event.statusFilter != null) {
        // Thực hiện lọc nếu event có yêu cầu statusFilter
        filteredOrders = allOrders
            .where((order) => order.status == event.statusFilter)
            .toList();
        print(
            '[OrderHistoryBloc] Filtered orders by status ${event.statusFilter}. Count: ${filteredOrders.length} / ${allOrders.length}');
      } else {
        // Không lọc nếu statusFilter là null (xem tất cả)
        filteredOrders = allOrders;
        print(
            '[OrderHistoryBloc] Showing all orders. Count: ${filteredOrders.length}');
      }
      // Emit state với danh sách đã lọc
      if (filteredOrders.isEmpty) {
        emit(OrderHistoryEmpty());
      } else {
        emit(OrderHistoryLoaded(filteredOrders));
      }
    } catch (e) {
      emit(OrderHistoryError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
