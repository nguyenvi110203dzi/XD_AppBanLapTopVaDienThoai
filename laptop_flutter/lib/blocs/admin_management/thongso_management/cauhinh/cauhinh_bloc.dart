import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Import models và repository
import '../../../../models/cauhinhbonho.dart';
import '../../../../models/product.dart'; // Import ProductModel
import '../../../../repositories/product_repository.dart'; // Repo quản lý product (để lấy list phone)
import '../../../../repositories/spec_repository.dart'; // Repo quản lý spec

part 'cauhinh_event.dart';
part 'cauhinh_state.dart';

class CauHinhBloc extends Bloc<CauHinhEvent, CauHinhState> {
  final SpecRepository _specRepository;
  final ProductRepository _productRepository; // Thêm ProductRepository

  CauHinhBloc({
    required SpecRepository specRepository,
    required ProductRepository productRepository, // Inject ProductRepository
  })  : _specRepository = specRepository,
        _productRepository = productRepository, // Gán ProductRepository
        super(const CauHinhState()) {
    // State ban đầu
    on<LoadAllCauHinh>(_onLoadAllCauHinh);
    on<AddCauHinh>(_onAddCauHinh);
    on<UpdateCauHinh>(_onUpdateCauHinh);
    on<DeleteCauHinh>(_onDeleteCauHinh);
  }

  // Xử lý tải danh sách cấu hình VÀ danh sách điện thoại
  Future<void> _onLoadAllCauHinh(
    LoadAllCauHinh event,
    Emitter<CauHinhState> emit,
  ) async {
    emit(state.copyWith(status: CauHinhStatus.loading, clearMessage: true));
    try {
      // Gọi song song để tải cả 2 danh sách
      final results = await Future.wait([
        _specRepository.getAllCauHinh(),
        _productRepository.getCategory1Products(), // Lấy danh sách điện thoại
      ]);

      final cauHinhList = results[0] as List<CauhinhBonho>;
      final phoneList = results[1] as List<ProductModel>;

      emit(state.copyWith(
        status: CauHinhStatus.loaded,
        cauHinhList: cauHinhList,
        phoneOptions: phoneList, // Lưu danh sách điện thoại vào state
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CauHinhStatus.failure,
        message: 'Lỗi tải dữ liệu: ${e.toString()}',
      ));
    }
  }

  // Xử lý thêm cấu hình mới
  Future<void> _onAddCauHinh(
    AddCauHinh event,
    Emitter<CauHinhState> emit,
  ) async {
    // Kiểm tra idProduct trước khi gửi (dù UI đã validate)
    if (event.cauHinhData.idProduct <= 0) {
      emit(state.copyWith(
          status: CauHinhStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
      return;
    }

    emit(state.copyWith(status: CauHinhStatus.submitting, clearMessage: true));
    try {
      final newCauHinh = await _specRepository.createCauHinh(event.cauHinhData);
      final updatedList = List<CauhinhBonho>.from(state.cauHinhList)
        ..insert(0, newCauHinh);
      emit(state.copyWith(
        status: CauHinhStatus.success,
        cauHinhList: updatedList,
        message: 'Thêm cấu hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CauHinhStatus.failure,
        message:
            'Lỗi thêm cấu hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      // Giữ lại danh sách cũ khi lỗi
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    }
  }

  // Xử lý cập nhật cấu hình
  Future<void> _onUpdateCauHinh(
    UpdateCauHinh event,
    Emitter<CauHinhState> emit,
  ) async {
    // Kiểm tra idProduct trước khi gửi
    if (event.cauHinhData.idProduct <= 0) {
      emit(state.copyWith(
          status: CauHinhStatus.failure,
          message: 'Lỗi: Chưa chọn sản phẩm để gán khi cập nhật.'));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
      return;
    }

    emit(state.copyWith(status: CauHinhStatus.submitting, clearMessage: true));
    try {
      final updatedCauHinh = await _specRepository.updateCauHinh(
          event.cauHinhId, event.cauHinhData);
      final updatedList = state.cauHinhList.map((ch) {
        return ch.id == updatedCauHinh.id ? updatedCauHinh : ch;
      }).toList();
      emit(state.copyWith(
        status: CauHinhStatus.success,
        cauHinhList: updatedList,
        message: 'Cập nhật cấu hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CauHinhStatus.failure,
        message:
            'Lỗi cập nhật cấu hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      // Giữ lại danh sách cũ khi lỗi
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    }
  }

  // Xử lý xóa cấu hình
  Future<void> _onDeleteCauHinh(
    DeleteCauHinh event,
    Emitter<CauHinhState> emit,
  ) async {
    // emit(state.copyWith(status: CauHinhStatus.submitting, clearMessage: true)); // Có thể thêm submitting
    try {
      await _specRepository.deleteCauHinh(event.cauHinhId);
      final updatedList =
          state.cauHinhList.where((ch) => ch.id != event.cauHinhId).toList();
      emit(state.copyWith(
        status: CauHinhStatus.success, // Hoặc loaded
        cauHinhList: updatedList,
        message: 'Xóa cấu hình thành công!',
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    } catch (e) {
      emit(state.copyWith(
        status: CauHinhStatus.failure, // Hoặc loaded
        message:
            'Lỗi xóa cấu hình: ${e.toString().replaceFirst('Exception: ', '')}',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: CauHinhStatus.loaded, clearMessage: true));
    }
  }
}
