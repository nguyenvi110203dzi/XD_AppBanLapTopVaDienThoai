part of 'pinsac_bloc.dart';

// Enum định nghĩa các trạng thái
enum PinSacStatus { initial, loading, loaded, submitting, success, failure }

class PinSacState extends Equatable {
  final PinSacStatus status;
  final List<PinSac> pinSacList; // Danh sách PinSac
  final List<ProductModel> phoneOptions; // Danh sách điện thoại cho ComboBox
  final String? message; // Thông báo

  const PinSacState({
    this.status = PinSacStatus.initial,
    this.pinSacList = const [],
    this.phoneOptions = const [],
    this.message,
  });

  PinSacState copyWith({
    PinSacStatus? status,
    List<PinSac>? pinSacList,
    List<ProductModel>? phoneOptions,
    String? message,
    bool clearMessage = false,
  }) {
    return PinSacState(
      status: status ?? this.status,
      pinSacList: pinSacList ?? this.pinSacList,
      phoneOptions: phoneOptions ?? this.phoneOptions,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, pinSacList, phoneOptions, message];
}
