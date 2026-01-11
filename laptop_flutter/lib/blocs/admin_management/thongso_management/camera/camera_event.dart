part of 'camera_bloc.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

// Event tải tất cả các CameraManhinh
class LoadAllCamera extends CameraEvent {}

// Event thêm CameraManhinh mới
class AddCamera extends CameraEvent {
  final CameraManhinh cameraData; // Dữ liệu mới (đã bao gồm idProduct)

  const AddCamera(this.cameraData);

  @override
  List<Object?> get props => [cameraData];
}

// Event cập nhật CameraManhinh
class UpdateCamera extends CameraEvent {
  final int cameraId;
  final CameraManhinh cameraData;

  const UpdateCamera({required this.cameraId, required this.cameraData});

  @override
  List<Object?> get props => [cameraId, cameraData];
}

// Event xóa CameraManhinh
class DeleteCamera extends CameraEvent {
  final int cameraId;

  const DeleteCamera(this.cameraId);

  @override
  List<Object?> get props => [cameraId];
}
