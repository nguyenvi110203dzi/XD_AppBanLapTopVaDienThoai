part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

// Event thêm sản phẩm (hoặc tăng số lượng nếu đã có)
class CartItemAdded extends CartEvent {
  final ProductModel product; // Truyền cả Product để lấy thông tin tạo CartItem

  const CartItemAdded(this.product);

  @override
  List<Object> get props => [product];
}

// Event xóa hoàn toàn một mục khỏi giỏ hàng
class CartItemRemoved extends CartEvent {
  final CartItem cartItem; // Truyền CartItem cần xóa

  const CartItemRemoved(this.cartItem);

  @override
  List<Object> get props => [cartItem];
}

// Event tăng số lượng
class CartItemQuantityIncreased extends CartEvent {
  final CartItem cartItem;

  const CartItemQuantityIncreased(this.cartItem);

  @override
  List<Object> get props => [cartItem];
}

// Event giảm số lượng (xóa nếu còn 1)
class CartItemQuantityDecreased extends CartEvent {
  final CartItem cartItem;

  const CartItemQuantityDecreased(this.cartItem);

  @override
  List<Object> get props => [cartItem];
}

// (Optional) Event xóa toàn bộ giỏ hàng
class CartCleared extends CartEvent {}
