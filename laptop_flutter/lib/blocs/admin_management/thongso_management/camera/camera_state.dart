part of 'camera_bloc.dart';

// Enum định nghĩa các trạng thái
enum CameraStatus { initial, loading, loaded, submitting, success, failure }

class CameraState extends Equatable {
  final CameraStatus status;
  final List<CameraManhinh> cameraList; // Danh sách CameraManhinh
  final List<ProductModel> phoneOptions; // Danh sách điện thoại cho ComboBox
  final String? message; // Thông báo

  const CameraState({
    this.status = CameraStatus.initial,
    this.cameraList = const [],
    this.phoneOptions = const [],
    this.message,
  });

  CameraState copyWith({
    CameraStatus? status,
    List<CameraManhinh>? cameraList,
    List<ProductModel>? phoneOptions,
    String? message,
    bool clearMessage = false,
  }) {
    return CameraState(
      status: status ?? this.status,
      cameraList: cameraList ?? this.cameraList,
      phoneOptions: phoneOptions ?? this.phoneOptions,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, cameraList, phoneOptions, message];
}
