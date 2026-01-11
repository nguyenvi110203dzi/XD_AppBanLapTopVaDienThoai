import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import Models và Repositories
import '../../../models/order.dart'; // Đảm bảo đường dẫn đúng
import '../../../repositories/order_repository.dart'; // Đảm bảo đường dẫn đúng

part 'admin_order_detail_event.dart';
part 'admin_order_detail_state.dart';

class AdminOrderDetailBloc
    extends Bloc<AdminOrderDetailEvent, AdminOrderDetailState> {
  final OrderRepository _orderRepository;

  // Constructor nhận OrderRepository
  AdminOrderDetailBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(AdminOrderDetailInitial()) {
    // Trạng thái ban đầu

    // Đăng ký các bộ xử lý sự kiện
    on<LoadAdminOrderDetail>(_onLoadAdminOrderDetail);
    on<UpdateAdminOrderStatus>(_onUpdateAdminOrderStatus);
    on<DeleteAdminOrder>(_onDeleteAdminOrder);
  }

  // Lấy Base URL để dùng trong UI (ví dụ: hiển thị ảnh)
  String get baseUrl => _orderRepository.baseUrl;

  Future<void> _onLoadAdminOrderDetail(
      LoadAdminOrderDetail event, Emitter<AdminOrderDetailState> emit) async {
    emit(AdminOrderDetailLoading());
    try {
      // Gọi API lấy chi tiết đơn hàng từ repository
      final order = await _orderRepository.getOrderById(event.orderId);
      emit(AdminOrderDetailLoaded(order));
    } catch (e) {
      emit(AdminOrderDetailLoadFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onUpdateAdminOrderStatus(
      UpdateAdminOrderStatus event, Emitter<AdminOrderDetailState> emit) async {
    // Lấy order hiện tại từ state (để hiển thị loading trên UI cũ)
    OrderModel? currentOrder;
    if (state is AdminOrderDetailLoaded) {
      currentOrder = (state as AdminOrderDetailLoaded).order;
    } else if (state is AdminOrderStatusUpdateFailure) {
      // Nếu trước đó bị lỗi update
      currentOrder = (state as AdminOrderStatusUpdateFailure).originalOrder;
    } else if (state is AdminOrderStatusUpdating) {
      // Nếu đang update rồi lại nhấn? (Tránh)
      return; // Không làm gì nếu đang update
    }

    if (currentOrder == null || currentOrder.id != event.orderId) {
      emit(const AdminOrderDetailLoadFailure(
          "Không thể xác định đơn hàng để cập nhật."));
      return;
    }

    emit(AdminOrderStatusUpdating(currentOrder)); // Phát state đang cập nhật
    try {
      // Gọi API cập nhật trạng thái
      final updatedOrder = await _orderRepository.updateOrderStatus(
          event.orderId, event.newStatus);
      emit(AdminOrderStatusUpdateSuccess(
          updatedOrder)); // Phát state thành công với order mới
    } catch (e) {
      emit(AdminOrderStatusUpdateFailure(
          e.toString().replaceFirst('Exception: ', ''),
          currentOrder)); // Phát lỗi và giữ order cũ
    }
  }

  Future<void> _onDeleteAdminOrder(
      DeleteAdminOrder event, Emitter<AdminOrderDetailState> emit) async {
    OrderModel? currentOrder;
    if (state is AdminOrderDetailLoaded) {
      currentOrder = (state as AdminOrderDetailLoaded).order;
    } else if (state is AdminOrderStatusUpdateFailure) {
      currentOrder = (state as AdminOrderStatusUpdateFailure).originalOrder;
    } else if (state is AdminOrderDeleteFailure) {
      currentOrder = (state as AdminOrderDeleteFailure).originalOrder;
    } else if (state is AdminOrderStatusUpdating) {
      currentOrder = (state as AdminOrderStatusUpdating).order;
    }

    if (currentOrder == null || currentOrder.id != event.orderId) {
      emit(const AdminOrderDetailLoadFailure(
          "Không thể xác định đơn hàng để xóa."));
      return;
    }

    if (state is AdminOrderDeleting) return; // Không làm gì nếu đang xóa

    emit(AdminOrderDeleting(event.orderId)); // Phát state đang xóa
    try {
      await _orderRepository.deleteOrder(event.orderId);
      emit(AdminOrderDeleteSuccess()); // Phát state xóa thành công
      // Bloc không tự điều hướng, UI sẽ xử lý việc này (ví dụ: Navigator.pop)
    } catch (e) {
      emit(AdminOrderDeleteFailure(e.toString().replaceFirst('Exception: ', ''),
          currentOrder)); // Phát lỗi
    }
  }
}
