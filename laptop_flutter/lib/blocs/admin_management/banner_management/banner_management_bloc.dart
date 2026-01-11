import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../models/banner.dart'; // Import model BannerModel
import '../../../repositories/banner_repository.dart'; // Import repo Banner

part 'banner_management_event.dart';
part 'banner_management_state.dart';

class BannerManagementBloc
    extends Bloc<BannerManagementEvent, BannerManagementState> {
  final BannerRepository bannerRepository; // Sử dụng BannerRepository

  BannerManagementBloc({required this.bannerRepository})
      : super(BannerInitial()) {
    on<LoadBanners>(_onLoadBanners);
    on<AddBanner>(_onAddBanner);
    on<UpdateBanner>(_onUpdateBanner);
    on<DeleteBanner>(_onDeleteBanner);
  }

  Future<void> _onLoadBanners(
      LoadBanners event, Emitter<BannerManagementState> emit) async {
    emit(BannerLoading());
    try {
      // Gọi hàm repo để lấy banner cho admin
      final banners = await bannerRepository.getAdminBanners();
      emit(BannerLoadSuccess(banners)); // Emit state tương ứng
    } catch (e) {
      emit(BannerLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAddBanner(
      AddBanner event, Emitter<BannerManagementState> emit) async {
    final currentState = state;
    List<BannerModel> currentBanners = [];
    if (currentState is BannerLoadSuccess) {
      currentBanners = currentState.banners;
    }
    emit(BannerOperationInProgress());
    try {
      // Gọi hàm repo createBanner
      await bannerRepository.createBanner(
          name: event.name, status: event.status, imageFile: event.imageFile);
      emit(
          const BannerOperationSuccess('Thêm banner thành công!')); // Thông báo
      add(LoadBanners()); // Tải lại danh sách
    } catch (e) {
      emit(
          BannerOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      if (currentBanners.isNotEmpty) {
        emit(BannerLoadSuccess(currentBanners));
      } else if (currentState is BannerInitial ||
          currentState is BannerLoadFailure) {
        emit(BannerInitial());
      }
    }
  }

  Future<void> _onUpdateBanner(
      UpdateBanner event, Emitter<BannerManagementState> emit) async {
    final currentState = state;
    List<BannerModel> currentBanners = [];
    if (currentState is BannerLoadSuccess) {
      currentBanners = currentState.banners;
    }
    emit(BannerOperationInProgress());
    try {
      // Gọi hàm repo updateBanner
      await bannerRepository.updateBanner(
          id: event.id,
          name: event.name,
          status: event.status,
          imageFile: event.imageFile);
      emit(const BannerOperationSuccess(
          'Cập nhật banner thành công!')); // Thông báo
      add(LoadBanners()); // Tải lại
    } catch (e) {
      emit(
          BannerOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      if (currentBanners.isNotEmpty) {
        emit(BannerLoadSuccess(currentBanners));
      } else if (currentState is BannerInitial ||
          currentState is BannerLoadFailure) {
        emit(BannerInitial());
      }
    }
  }

  Future<void> _onDeleteBanner(
      DeleteBanner event, Emitter<BannerManagementState> emit) async {
    final currentState = state;
    List<BannerModel> currentBanners = [];
    if (currentState is BannerLoadSuccess) {
      currentBanners = currentState.banners;
    }
    emit(BannerOperationInProgress());
    try {
      // Gọi hàm repo deleteBanner
      await bannerRepository.deleteBanner(event.id);
      emit(const BannerOperationSuccess('Xóa banner thành công!')); // Thông báo
      add(LoadBanners()); // Tải lại
    } catch (e) {
      emit(
          BannerOperationFailure(e.toString().replaceFirst('Exception: ', '')));
      if (currentBanners.isNotEmpty) {
        emit(BannerLoadSuccess(currentBanners));
      } else if (currentState is BannerInitial ||
          currentState is BannerLoadFailure) {
        emit(BannerInitial());
      }
    }
  }
}
