import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../models/brand.dart';
import '../../../repositories/brand_repository.dart';

part 'brand_management_event.dart';
part 'brand_management_state.dart';

class BrandManagementBloc
    extends Bloc<BrandManagementEvent, BrandManagementState> {
  final BrandRepository brandRepository;

  BrandManagementBloc({required this.brandRepository}) : super(BrandInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<AddBrand>(_onAddBrand);
    on<UpdateBrand>(_onUpdateBrand);
    on<DeleteBrand>(_onDeleteBrand);
  }

  Future<void> _onLoadBrands(
      LoadBrands event, Emitter<BrandManagementState> emit) async {
    emit(BrandLoading());
    try {
      final brands = await brandRepository.getBrands();
      emit(BrandLoadSuccess(brands));
    } catch (e) {
      emit(BrandLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAddBrand(
      AddBrand event, Emitter<BrandManagementState> emit) async {
    // Giữ lại trạng thái danh sách hiện tại nếu có
    final currentState = state;
    List<Brand> currentBrands = [];
    if (currentState is BrandLoadSuccess) {
      currentBrands = currentState.brands;
    }

    emit(BrandOperationInProgress()); // Báo đang xử lý
    try {
      await brandRepository.createBrand(
          name: event.name, imageFile: event.imageFile);
      emit(const BrandOperationSuccess('Thêm thương hiệu thành công!'));
      // Tải lại danh sách sau khi thêm thành công
      add(LoadBrands()); // << Tải lại danh sách
      // Hoặc nếu muốn cập nhật ngay lập tức mà không cần gọi API lại:
      // final updatedBrands = await brandRepository.getBrands(); // Gọi API để lấy list mới nhất
      // emit(BrandLoadSuccess(updatedBrands)); // Cập nhật lại state thành công với list mới
    } catch (e) {
      emit(BrandOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      // Quay lại trạng thái danh sách trước đó nếu thao tác thất bại
      if (currentBrands.isNotEmpty) {
        emit(BrandLoadSuccess(currentBrands));
      } else if (currentState is BrandInitial ||
          currentState is BrandLoadFailure) {
        // Nếu trước đó chưa load được hoặc là initial thì quay về initial
        emit(BrandInitial()); // Hoặc emit lại lỗi load cũ nếu cần
      }
    }
  }

  Future<void> _onUpdateBrand(
      UpdateBrand event, Emitter<BrandManagementState> emit) async {
    final currentState = state;
    List<Brand> currentBrands = [];
    if (currentState is BrandLoadSuccess) {
      currentBrands = currentState.brands;
    }

    emit(BrandOperationInProgress());
    try {
      await brandRepository.updateBrand(
          id: event.id, name: event.name, imageFile: event.imageFile);
      emit(const BrandOperationSuccess('Cập nhật thương hiệu thành công!'));
      add(LoadBrands()); // Tải lại danh sách
    } catch (e) {
      emit(BrandOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      if (currentBrands.isNotEmpty) {
        emit(BrandLoadSuccess(currentBrands));
      } else if (currentState is BrandInitial ||
          currentState is BrandLoadFailure) {
        emit(BrandInitial());
      }
    }
  }

  Future<void> _onDeleteBrand(
      DeleteBrand event, Emitter<BrandManagementState> emit) async {
    final currentState = state;
    List<Brand> currentBrands = [];
    if (currentState is BrandLoadSuccess) {
      currentBrands = currentState.brands;
    }
    emit(BrandOperationInProgress());
    try {
      await brandRepository.deleteBrand(event.id);
      emit(const BrandOperationSuccess('Xóa thương hiệu thành công!'));
      add(LoadBrands()); // Tải lại danh sách
      // Hoặc cập nhật local state nếu muốn nhanh hơn (nhưng cần đảm bảo server đã xóa thành công)
      if (currentState is BrandLoadSuccess) {
        final updatedList =
            currentState.brands.where((brand) => brand.id != event.id).toList();
        emit(BrandLoadSuccess(updatedList));
      } else {
        add(LoadBrands()); // Nếu state hiện tại không phải success thì load lại cho chắc
      }
    } catch (e) {
      emit(BrandOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      // Giữ nguyên danh sách cũ nếu xóa thất bại
      if (currentBrands.isNotEmpty) {
        emit(BrandLoadSuccess(currentBrands));
      } else if (currentState is BrandInitial ||
          currentState is BrandLoadFailure) {
        emit(BrandInitial());
      }
    }
  }
}
