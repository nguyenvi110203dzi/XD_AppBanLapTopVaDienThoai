import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Để format tiền tệ

import '../blocs/cart/cart_bloc.dart';
import '../config/app_constants.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    bool onSale = product.oldprice != null && product.oldprice! > product.price;
    double discountPercent = onSale
        ? ((product.oldprice! - product.price) / product.oldprice!) * 100
        : 0;
    bool inStock = product.quantity > 0;

    return InkWell(
      onTap: onTap, // Xử lý sự kiện nhấn vào sản phẩm (chuyển trang chi tiết)
      child: Card(
        elevation: 2, // Ứng dụng bóng dưới
        clipBehavior: Clip.antiAlias, //Để bo góc ảnh
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Căn giữa theo chiều ngang
          children: [
            AspectRatio(
              aspectRatio: 14 / 6,
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  Container(
                    width: double.infinity, // Chiếm hết chiều rộng card
                    child: product.image != null
                        ? Image.network(
                      AppConstants.baseUrl + product.image!,
                            fit: BoxFit
                                .cover, // Hoặc BoxFit.contain tùy thiết kế
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                    child: Icon(Icons.error_outline,
                                        color: Colors.grey)),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey)),
                          ),
                  ),
                  if (onSale && discountPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (!inStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Text('Hết hàng',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // mainAxisSize: MainAxisSize.min, // Dùng nếu phần ảnh không Expanded
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Đẩy giá và nút ra 2 bên
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Căn giữa theo chiều dọc
                        children: [
                          // Cột chứa Giá / Giá cũ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatCurrency.format(product.price),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // Kích thước giá phù hợp card
                                ),
                              ),
                              if (onSale)
                                Text(
                                  formatCurrency.format(product.oldprice),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 10, // Giá cũ nhỏ hơn
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              // Thay đổi icon nếu hết hàng
                              inStock
                                  ? Icons.add_shopping_cart_outlined
                                  : Icons.remove_shopping_cart,
                            ),
                            color: inStock
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey, // Màu khác hoặc xám nếu hết hàng
                            iconSize: 30, // Kích thước icon nhỏ hơn
                            padding: EdgeInsets.zero, // Bỏ padding mặc định
                            constraints:
                                const BoxConstraints(), // Bỏ ràng buộc kích thước mặc định
                            tooltip: inStock ? 'Thêm vào giỏ hàng' : 'Hết hàng',
                            onPressed: inStock // Chỉ cho phép nhấn nếu còn hàng
                                ? () {
                                    // Gửi event đến CartBloc
                                    context
                                        .read<CartBloc>()
                                        .add(CartItemAdded(product));
                                    // Hiển thị SnackBar thông báo
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${product.name} đã được thêm vào giỏ hàng.'),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior
                                            .floating, // Nổi lên thay vì đè BottomNav
                                        margin: const EdgeInsets.only(
                                            bottom:
                                                kBottomNavigationBarHeight + 10,
                                            left: 15,
                                            right:
                                                15), // Căn chỉnh vị trí SnackBar
                                      ),
                                    );
                                  }
                                : null, // Vô hiệu hóa nút nếu hết hàng
                          ),
                          // --- KẾT THÚC NÚT THÊM VÀO GIỎ HÀNG ---
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
