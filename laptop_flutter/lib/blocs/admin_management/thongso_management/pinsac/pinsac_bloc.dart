import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import models và repositories
import '../../../../models/pinvasac.dart';
import '../../../../models/product.dart';
import '../../../../repositories/product_repository.dart';
import '../../../../repositories/spec_repository.dart';

part 'pinsac_event.dart';
part 'pinsac_state.dart';

class PinSacBloc extends Bloc<PinSacEvent, PinSacState> {
  final SpecRepository _specRepository;
  final ProductRepository _productRepository;

  PinSacBloc({
    required SpecRepository specRepository,
    required ProductRepository productRepository,
  })  : _specRepository = specRepository,
        _productRepository = productRepository,
        super(const PinSacState()) {
    on<LoadAllPinSac>(_onLoadAllPinSac);
    on<AddPinSac>(_onAddPinSac);
    on<UpdatePinSac>(_onUpdatePinSac);
    on<DeletePinSac>(_onDeletePinSac);
  }

  // Load danh sách PinSac và danh sách Điện thoại
  Future<void> _onLoadAllPinSac(
    LoadAllPinSac event,
    Emitter<PinSacState> emit,
  ) async {
    emit(state.copyWith(status: PinSacStatus.loading, clearMessage: true));
    try {
      final results = await Future.wait([
        _specRepository.getAllPinSac(), // Gọi hàm repo tương ứng
        _productRepository.getCategory1Products(),
      ]);

      final pinSacList = results[0] as List<PinSac>;
      final phoneList = results[1] as List<ProductModel>;

      emit(state.copyWith(
        status: PinSacStatus.loaded,
        pinSacList: pinSacList,
        phoneOptions: phoneList,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PinSacStatus.failure,
        message: 'Lỗi tải dữ liệu Pin/Sạc: ${e.toString()}',
      ));
    }
  }

  // Thêm PinSac mới
  Future<void> _onAddPinSac(
    AddPinSac event,
    Emitter<PinSacState> emit,
  ) async {
    if (event.pinSacData.idProduct <= 0) {
      emit(state.copyWith(
          status: PinSacStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
      return;
    }
    emit(state.copyWith(status: PinSacStatus.submitting, clearMessage: true));
    try {
      final newPinSac =
          await _specRepository.createPinSac(event.pinSacData); // Gọi hàm repo
      final updatedList = List<PinSac>.from(state.pinSacList)
        ..insert(0, newPinSac);
      emit(state.copyWith(
        status: PinSacStatus.success,
        pinSacList: updatedList,
        message: 'Thêm Pin/Sạc thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: PinSacStatus.failure,
        message:
            'Lỗi thêm Pin/Sạc: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    }
  }

  // Cập nhật PinSac
  Future<void> _onUpdatePinSac(
    UpdatePinSac event,
    Emitter<PinSacState> emit,
  ) async {
    if (event.pinSacData.idProduct <= 0) {
      emit(state.copyWith(
          status: PinSacStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán khi cập nhật.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
      return;
    }
    emit(state.copyWith(status: PinSacStatus.submitting, clearMessage: true));
    try {
      final updatedPinSac = await _specRepository.updatePinSac(
          event.pinSacId, event.pinSacData); // Gọi hàm repo
      final updatedList = state.pinSacList.map((ps) {
        return ps.id == updatedPinSac.id ? updatedPinSac : ps;
      }).toList();
      emit(state.copyWith(
        status: PinSacStatus.success,
        pinSacList: updatedList,
        message: 'Cập nhật Pin/Sạc thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: PinSacStatus.failure,
        message:
            'Lỗi cập nhật Pin/Sạc: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    }
  }

  // Xóa PinSac
  Future<void> _onDeletePinSac(
    DeletePinSac event,
    Emitter<PinSacState> emit,
  ) async {
    try {
      await _specRepository.deletePinSac(event.pinSacId); // Gọi hàm repo
      final updatedList =
          state.pinSacList.where((ps) => ps.id != event.pinSacId).toList();
      emit(state.copyWith(
        status: PinSacStatus.success, // Hoặc loaded
        pinSacList: updatedList,
        message: 'Xóa Pin/Sạc thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: PinSacStatus.failure, // Hoặc loaded
        message:
            'Lỗi xóa Pin/Sạc: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: PinSacStatus.loaded, clearMessage: true));
    }
  }
}
