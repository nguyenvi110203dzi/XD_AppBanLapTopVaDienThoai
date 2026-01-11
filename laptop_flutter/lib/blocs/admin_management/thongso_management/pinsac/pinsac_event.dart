part of 'pinsac_bloc.dart';

abstract class PinSacEvent extends Equatable {
  const PinSacEvent();

  @override
  List<Object?> get props => [];
}

// Event tải tất cả PinSac
class LoadAllPinSac extends PinSacEvent {}

// Event thêm PinSac mới
class AddPinSac extends PinSacEvent {
  final PinSac pinSacData; // Dữ liệu mới (đã bao gồm idProduct)

  const AddPinSac(this.pinSacData);

  @override
  List<Object?> get props => [pinSacData];
}

// Event cập nhật PinSac
class UpdatePinSac extends PinSacEvent {
  final int pinSacId;
  final PinSac pinSacData;

  const UpdatePinSac({required this.pinSacId, required this.pinSacData});

  @override
  List<Object?> get props => [pinSacId, pinSacData];
}

// Event xóa PinSac
class DeletePinSac extends PinSacEvent {
  final int pinSacId;

  const DeletePinSac(this.pinSacId);

  @override
  List<Object?> get props => [pinSacId];
}
