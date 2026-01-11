import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';

// Import các repo khác nếu cần load feedback, related products

part 'product_detail_event.dart';
part 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository productRepository;
  // Thêm các repo khác nếu cần

  ProductDetailBloc({required this.productRepository})
      : super(ProductDetailLoading()) {
    on<LoadProductDetail>(_onLoadProductDetail);
  }

  Future<void> _onLoadProductDetail(
      LoadProductDetail event, Emitter<ProductDetailState> emit) async {
    emit(ProductDetailLoading());
    try {
      // Chỉ load thông tin sản phẩm chính trước
      final product = await productRepository.getProductById(event.productId);

      emit(ProductDetailLoaded(
        product: product,
        // feedbacks: feedbacks,
        // relatedProducts: relatedProducts,
      ));
    } catch (e) {
      emit(ProductDetailError(e.toString()));
    }
  }
}
