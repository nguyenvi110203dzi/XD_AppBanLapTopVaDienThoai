import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/banner.dart'; // Đảm bảo đúng tên model
import '../../models/product.dart';
import '../../repositories/banner_repository.dart';
import '../../repositories/product_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BannerRepository bannerRepository;
  final ProductRepository productRepository;

  HomeBloc({required this.bannerRepository, required this.productRepository})
      : super(HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
      LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      // Gọi API đồng thời để tăng tốc độ
      final results = await Future.wait([
        bannerRepository.getBanners(),
        productRepository.getAllProducts(), // Lấy tất cả để lọc sale
        productRepository.getNewProducts(), // Lấy sản phẩm mới
      ]);

      final banners = results[0] as List<BannerModel>;
      final allProducts = results[1] as List<ProductModel>;
      final newProducts = results[2] as List<ProductModel>;

      // Lọc sản phẩm sale từ allProducts
      final saleProducts = allProducts
          .where((product) => product.oldprice != null && product.oldprice! > 0)
          .toList();

      emit(HomeLoaded(
        banners: banners,
        saleProducts: saleProducts,
        newProducts: newProducts,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
