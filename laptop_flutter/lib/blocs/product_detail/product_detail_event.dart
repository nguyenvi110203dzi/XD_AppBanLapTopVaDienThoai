part of 'product_detail_bloc.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object> get props => [];
}

// Event yêu cầu tải chi tiết sản phẩm dựa vào ID
class LoadProductDetail extends ProductDetailEvent {
  final int productId;

  const LoadProductDetail(this.productId);

  @override
  List<Object> get props => [productId];
}

// Có thể thêm các event khác sau này (ví dụ: LoadFeedback, LoadRelatedProducts)
