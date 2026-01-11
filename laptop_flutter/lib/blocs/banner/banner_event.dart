part of 'banner_bloc.dart';

abstract class BannerEvent extends Equatable {
  const BannerEvent();
  @override
  List<Object> get props => [];
}

// Event để tải danh sách banners
class LoadBanners extends BannerEvent {}
