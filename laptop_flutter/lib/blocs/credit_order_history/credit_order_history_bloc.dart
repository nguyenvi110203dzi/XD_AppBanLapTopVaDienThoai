import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

part 'credit_order_history_event.dart';
part 'credit_order_history_state.dart';

class CreditOrderHistoryBloc
    extends Bloc<CreditOrderHistoryEvent, CreditOrderHistoryState> {
  final CreditOrderRepository creditOrderRepository;

  CreditOrderHistoryBloc({required this.creditOrderRepository})
      : super(CreditOrderHistoryInitial()) {
    on<LoadMyCreditOrders>(_onLoadMyCreditOrders);
  }

  Future<void> _onLoadMyCreditOrders(
    LoadMyCreditOrders event,
    Emitter<CreditOrderHistoryState> emit,
  ) async {
    List<CreditOrderModel>? currentOrders;
    if (state is CreditOrderHistoryLoaded) {
      currentOrders = (state as CreditOrderHistoryLoaded).orders;
    } else if (state is CreditOrderHistoryLoading) {
      // Nếu đang loading mà gọi load lại
      currentOrders = (state as CreditOrderHistoryLoading).previousOrders;
    }

    emit(CreditOrderHistoryLoading(
        previousOrders: currentOrders)); // Truyền previousOrders
    try {
      final orders = await creditOrderRepository.getMyCreditOrders(
          status: event.statusFilter);
      if (orders.isEmpty) {
        emit(CreditOrderHistoryEmpty());
      } else {
        emit(CreditOrderHistoryLoaded(orders));
      }
    } catch (e) {
      // Nếu lỗi, có thể emit lại state Loading với previousOrders hoặc emit Error
      emit(CreditOrderHistoryError(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
