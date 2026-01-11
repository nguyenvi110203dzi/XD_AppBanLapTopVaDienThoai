part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

// Trạng thái ban đầu hoặc đang tải
class HomeLoading extends HomeState {}

// Trạng thái tải thành công
class HomeLoaded extends HomeState {
  final List<BannerModel> banners;
  final List<ProductModel> saleProducts;
  final List<ProductModel> newProducts;

  const HomeLoaded({
    this.banners = const [],
    this.saleProducts = const [],
    this.newProducts = const [],
  });

  @override
  List<Object?> get props => [banners, saleProducts, newProducts];
}

// Trạng thái lỗi
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
