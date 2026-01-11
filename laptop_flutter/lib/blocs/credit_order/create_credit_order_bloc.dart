import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/credit_order_repository.dart';

part 'create_credit_order_event.dart';
part 'create_credit_order_state.dart';

class CreateCreditOrderBloc
    extends Bloc<CreateCreditOrderEvent, CreateCreditOrderState> {
  final CreditOrderRepository creditOrderRepository;

  CreateCreditOrderBloc({required this.creditOrderRepository})
      : super(CreateCreditOrderInitial()) {
    on<SubmitCreditOrder>(_onSubmitCreditOrder);
  }

  Future<void> _onSubmitCreditOrder(
    SubmitCreditOrder event,
    Emitter<CreateCreditOrderState> emit,
  ) async {
    emit(CreateCreditOrderInProgress());
    try {
      final newOrder = await creditOrderRepository.createCreditOrder(
        items: event.items,
        note: event.note,
        dueDate: event.dueDate,
      );
      emit(CreateCreditOrderSuccess(newOrder));
    } catch (e) {
      emit(CreateCreditOrderFailure(
          e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
