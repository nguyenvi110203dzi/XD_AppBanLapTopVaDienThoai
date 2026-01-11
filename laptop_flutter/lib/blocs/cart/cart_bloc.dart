import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart'; // Import HydratedBloc

import '../../models/cart_item.dart';
import '../../models/product.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends HydratedBloc<CartEvent, CartState> {
  // Khởi tạo state ban đầu là giỏ hàng rỗng
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartItemQuantityIncreased>(_onQuantityIncreased);
    on<CartItemQuantityDecreased>(_onQuantityDecreased);
    on<CartCleared>(_onCartCleared);
  }

  // Xử lý thêm sản phẩm
  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final existingItemIndex =
        updatedItems.indexWhere((item) => item.productId == event.product.id);

    if (existingItemIndex >= 0) {
      // Đã có: Kiểm tra trước khi tăng số lượng
      final existingItem = updatedItems[existingItemIndex];
      // Chỉ tăng nếu số lượng hiện tại < số lượng tồn kho đã lưu
      if (existingItem.quantity < existingItem.availableStock) {
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
        print('Increased quantity for ${event.product.name}');
        emit(CartState(items: updatedItems));
      } else {
        print(
            'Cannot increase quantity for ${event.product.name}. Stock limit reached.');
        // Optional: Có thể emit một state riêng để báo lỗi hoặc không làm gì cả
        // emit(CartOperationError(state.items, 'Số lượng tồn kho không đủ'));
      }
    } else {
      // Chưa có: Kiểm tra xem có hàng không trước khi thêm
      if (event.product.quantity > 0) {
        // Thêm mới với số lượng tồn kho ban đầu
        updatedItems.add(CartItem.fromProduct(event.product, quantity: 1));
        print('Added new item ${event.product.name}');
        emit(CartState(items: updatedItems));
      } else {
        print('Cannot add ${event.product.name}. Out of stock.');
        // Optional: Báo lỗi sản phẩm hết hàng
      }
    }
    //emit(CartState(items: updatedItems)); // Phát ra state mới
  }

  // Xử lý xóa sản phẩm
  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    updatedItems
        .removeWhere((item) => item.productId == event.cartItem.productId);
    print('Removed item ${event.cartItem.name}');
    emit(CartState(items: updatedItems));
  }

  // Xử lý tăng số lượng
  void _onQuantityIncreased(
      CartItemQuantityIncreased event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final itemIndex = updatedItems
        .indexWhere((item) => item.productId == event.cartItem.productId);

    if (itemIndex >= 0) {
      final item = updatedItems[itemIndex];
      // Chỉ tăng nếu số lượng hiện tại < số lượng tồn kho đã lưu
      if (item.quantity < item.availableStock) {
        updatedItems[itemIndex] = item.copyWith(quantity: item.quantity + 1);
        print('Increased quantity for ${item.name} via button');
        emit(CartState(items: updatedItems));
      } else {
        print(
            'Cannot increase quantity for ${item.name}. Stock limit reached.');
        // Optional: Báo lỗi
      }
    }
  }

  // Xử lý giảm số lượng
  void _onQuantityDecreased(
      CartItemQuantityDecreased event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    final itemIndex = updatedItems
        .indexWhere((item) => item.productId == event.cartItem.productId);
    if (itemIndex >= 0) {
      final item = updatedItems[itemIndex];
      if (item.quantity > 1) {
        updatedItems[itemIndex] = item.copyWith(quantity: item.quantity - 1);
        print('Decreased quantity for ${item.name}');
        emit(CartState(items: updatedItems));
      } else {
        // Nếu số lượng là 1, xóa khỏi giỏ hàng luôn
        updatedItems.removeAt(itemIndex);
        print('Removed item ${item.name} by decreasing quantity to 0');
        emit(CartState(items: updatedItems));
      }
    }
  }

  // Xử lý xóa toàn bộ giỏ hàng (nếu cần)
  void _onCartCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState(items: [])); // Phát ra state rỗng
  }

  // --- Override phương thức của HydratedBloc ---
  @override
  CartState? fromJson(Map<String, dynamic> json) {
    // Đọc state từ storage
    try {
      return CartState.fromJson(json);
    } catch (e) {
      print("Error reading cart state from storage: $e");
      return null; // Trả về null nếu có lỗi đọc
    }
  }

  @override
  Map<String, dynamic>? toJson(CartState state) {
    // Ghi state vào storage
    try {
      return state.toJson();
    } catch (e) {
      print("Error writing cart state to storage: $e");
      return null; // Trả về null nếu có lỗi ghi
    }
  }
// --- Hết phần HydratedBloc ---
}
