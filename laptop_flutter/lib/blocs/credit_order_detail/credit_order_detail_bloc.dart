import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

part 'credit_order_detail_event.dart';
part 'credit_order_detail_state.dart';

class CreditOrderDetailBloc
    extends Bloc<CreditOrderDetailEvent, CreditOrderDetailState> {
  final CreditOrderRepository creditOrderRepository;

  CreditOrderDetailBloc({required this.creditOrderRepository})
      : super(CreditOrderDetailInitial()) {
    on<LoadMyCreditOrderDetail>(_onLoadMyCreditOrderDetail);
  }

  Future<void> _onLoadMyCreditOrderDetail(
    LoadMyCreditOrderDetail event,
    Emitter<CreditOrderDetailState> emit,
  ) async {
    emit(CreditOrderDetailLoading());
    try {
      final order =
          await creditOrderRepository.getMyCreditOrderDetail(event.orderId);
      emit(CreditOrderDetailLoaded(order));
    } catch (e) {
      emit(
          CreditOrderDetailError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
