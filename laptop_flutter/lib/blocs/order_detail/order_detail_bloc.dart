import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/order.dart'; // Import Order model
import '../../repositories/order_repository.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  final OrderRepository orderRepository;

  OrderDetailBloc({required this.orderRepository})
      : super(OrderDetailLoading()) {
    on<LoadOrderDetail>(_onLoadOrderDetail);
  }

  Future<void> _onLoadOrderDetail(
      LoadOrderDetail event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailLoading());
    try {
      final order = await orderRepository.getOrderById(event.orderId);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderDetailError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
