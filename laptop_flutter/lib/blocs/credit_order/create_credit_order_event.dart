part of 'create_credit_order_bloc.dart';

abstract class CreateCreditOrderEvent extends Equatable {
  const CreateCreditOrderEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCreditOrder extends CreateCreditOrderEvent {
  final List<Map<String, dynamic>> items;
  final String? note;
  final DateTime? dueDate;

  const SubmitCreditOrder({required this.items, this.note, this.dueDate});

  @override
  List<Object?> get props => [items, note, dueDate];
}
