part of 'cart_bloc.dart';

// Dùng Equatable để dễ so sánh state
class CartState extends Equatable {
  final List<CartItem> items;

  const CartState({this.items = const []}); // Mặc định là list rỗng

  // Tính tổng tiền
  int get totalPrice =>
      items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  // Tính tổng số lượng (tất cả các sản phẩm)
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Tính tổng số loại sản phẩm (số dòng trong giỏ hàng)
  int get itemCount => items.length;

  @override
  List<Object> get props => [items]; // Quan trọng cho Equatable

  // --- Cần cho HydratedBloc ---
  Map<String, dynamic> toJson() {
    // Chuyển List<CartItem> thành List<Map<String, dynamic>>
    return {'items': items.map((item) => item.toJson()).toList()};
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    // Chuyển List<dynamic> (list các map) thành List<CartItem>
    var itemsList = json['items'] as List<dynamic>? ?? [];
    List<CartItem> parsedItems = itemsList
        .map((itemJson) => CartItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();
    return CartState(items: parsedItems);
  }
// --- Hết phần cho HydratedBloc ---
}
