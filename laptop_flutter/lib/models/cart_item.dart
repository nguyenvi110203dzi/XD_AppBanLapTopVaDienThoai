import 'package:equatable/equatable.dart';

import 'product.dart'; // Import model Product

class CartItem extends Equatable {
  final int productId; // Chỉ cần lưu ID để tra cứu hoặc hiển thị cơ bản
  final String name;
  final int price;
  final String? image; // Đường dẫn asset
  final int quantity;
  final int availableStock; // gioi han ton kho luc them san pham vao gio hang
  // Thêm các thuộc tính khác của Product nếu cần hiển thị trực tiếp trong giỏ hàng

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    required this.quantity,
    required this.availableStock, // << Thêm vào constructor
  });

  // Factory để tạo CartItem từ Product
  factory CartItem.fromProduct(ProductModel product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      image: product.image,
      quantity: quantity,
      availableStock: product.quantity, // << Lấy tồn kho từ Product
    );
  }

  // Phương thức để tạo bản sao với số lượng mới (immutable)
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      price: price,
      image: image,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock, // << Giữ nguyên availableStock khi copy
    );
  }

  // Chuyển đổi sang JSON để HydratedBloc lưu trữ
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'image': image,
      'quantity': quantity,
      'availableStock': availableStock, // << Thêm vào JSON
    };
  }

  // Tạo đối tượng từ JSON khi HydratedBloc đọc từ storage
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      image: json['image'] as String?,
      quantity: json['quantity'] as int,
      availableStock: json['availableStock'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [productId, name, price, image, quantity, availableStock];
}
