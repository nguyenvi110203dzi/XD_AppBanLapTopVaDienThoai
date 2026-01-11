import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import models và repositories
import '../../../../models/cameramanhinh.dart';
import '../../../../models/product.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../repositories/spec_repository.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final SpecRepository _specRepository;
  final ProductRepository _productRepository;

  CameraBloc({
    required SpecRepository specRepository,
    required ProductRepository productRepository,
  })  : _specRepository = specRepository,
        _productRepository = productRepository,
        super(const CameraState()) {
    on<LoadAllCamera>(_onLoadAllCamera);
    on<AddCamera>(_onAddCamera);
    on<UpdateCamera>(_onUpdateCamera);
    on<DeleteCamera>(_onDeleteCamera);
  }

  // Load danh sách Camera và danh sách Điện thoại
  Future<void> _onLoadAllCamera(
    LoadAllCamera event,
    Emitter<CameraState> emit,
  ) async {
    emit(state.copyWith(status: CameraStatus.loading, clearMessage: true));
    try {
      final results = await Future.wait([
        _specRepository.getAllCameraManhinh(), // Gọi hàm repo tương ứng
        _productRepository.getCategory1Products(),
      ]);

      final cameraList = results[0] as List<CameraManhinh>;
      final phoneList = results[1] as List<ProductModel>;

      emit(state.copyWith(
        status: CameraStatus.loaded,
        cameraList: cameraList,
        phoneOptions: phoneList,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.failure,
        message: 'Lỗi tải dữ liệu Camera: ${e.toString()}',
      ));
    }
  }

  // Thêm Camera mới
  Future<void> _onAddCamera(
    AddCamera event,
    Emitter<CameraState> emit,
  ) async {
    if (event.cameraData.idProduct <= 0) {
      emit(state.copyWith(
          status: CameraStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
      return;
    }
    emit(state.copyWith(status: CameraStatus.submitting, clearMessage: true));
    try {
      final newCamera = await _specRepository
          .createCameraManhinh(event.cameraData); // Gọi hàm repo
      final updatedList = List<CameraManhinh>.from(state.cameraList)
        ..insert(0, newCamera);
      emit(state.copyWith(
        status: CameraStatus.success,
        cameraList: updatedList,
        message: 'Thêm Camera/Màn hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.failure,
        message:
            'Lỗi thêm Camera/Màn hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    }
  }

  // Cập nhật Camera
  Future<void> _onUpdateCamera(
    UpdateCamera event,
    Emitter<CameraState> emit,
  ) async {
    if (event.cameraData.idProduct <= 0) {
      emit(state.copyWith(
          status: CameraStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán khi cập nhật.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
      return;
    }
    emit(state.copyWith(status: CameraStatus.submitting, clearMessage: true));
    try {
      final updatedCamera = await _specRepository.updateCameraManhinh(
          event.cameraId, event.cameraData); // Gọi hàm repo
      final updatedList = state.cameraList.map((cam) {
        return cam.id == updatedCamera.id ? updatedCamera : cam;
      }).toList();
      emit(state.copyWith(
        status: CameraStatus.success,
        cameraList: updatedList,
        message: 'Cập nhật Camera/Màn hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.failure,
        message:
            'Lỗi cập nhật Camera/Màn hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    }
  }

  // Xóa Camera
  Future<void> _onDeleteCamera(
    DeleteCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      await _specRepository.deleteCameraManhinh(event.cameraId); // Gọi hàm repo
      final updatedList =
          state.cameraList.where((cam) => cam.id != event.cameraId).toList();
      emit(state.copyWith(
        status: CameraStatus.success, // Hoặc loaded
        cameraList: updatedList,
        message: 'Xóa Camera/Màn hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.failure, // Hoặc loaded
        message:
            'Lỗi xóa Camera/Màn hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CameraStatus.loaded, clearMessage: true));
    }
  }
}
