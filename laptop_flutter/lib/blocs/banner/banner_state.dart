part of 'banner_bloc.dart';

// Lớp cơ sở cho các trạng thái Banner
abstract class BannerState extends Equatable {
  const BannerState();

  @override
  List<Object> get props => [];
}

// Trạng thái khởi tạo
class BannerInitial extends BannerState {}

// Trạng thái đang tải
class BannerLoading extends BannerState {}

// Trạng thái tải thành công
class BannersLoaded extends BannerState {
  // Sử dụng BannerModel cho nhất quán
  final List<BannerModel> banners;

  const BannersLoaded(this.banners);

  @override
  List<Object> get props => [banners];
}

// Trạng thái lỗi
class BannerError extends BannerState {
  final String message;

  const BannerError(this.message);

  @override
  List<Object> get props => [message];
}
