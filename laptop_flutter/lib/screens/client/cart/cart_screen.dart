import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/cart/cart_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../models/cart_item.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          // Có thể thêm nút xóa tất cả nếu muốn
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              // Xác nhận trước khi xóa
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Xóa giỏ hàng?'),
                  content: Text('Bạn có chắc muốn xóa tất cả sản phẩm?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Hủy')),
                    TextButton(
                      onPressed: () {
                        context.read<CartBloc>().add(CartCleared());
                        Navigator.pop(ctx);
                      },
                      child: Text('Xóa', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Text('Giỏ hàng của bạn đang trống.'),
            );
          }

          return Column(
            children: [
              Expanded(
                // ListView chiếm phần lớn không gian
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _buildCartItemTile(context, item, formatCurrency);
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                ),
              ),
              // Phần tổng tiền và thanh toán
              _buildSummarySection(context, state, formatCurrency),
            ],
          );
        },
      ),
    );
  }

  // Widget hiển thị một item trong giỏ hàng
  Widget _buildCartItemTile(
      BuildContext context, CartItem item, NumberFormat formatCurrency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hình ảnh
        SizedBox(
          width: 80,
          height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.image != null
                ? Image.network((AppConstants.baseUrl + item.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image))
                : Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported)),
          ),
        ),
        const SizedBox(width: 12),
        // Thông tin và số lượng
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(formatCurrency.format(item.price),
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Bộ điều khiển số lượng
              Row(
                children: [
                  _buildQuantityButton(
                    context: context,
                    icon: Icons.remove,
                    onPressed: () {
                      context
                          .read<CartBloc>()
                          .add(CartItemQuantityDecreased(item));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('${item.quantity}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  _buildQuantityButton(
                    context: context,
                    icon: Icons.add,
                    onPressed: item.quantity < item.availableStock
                        ? () {
                            context
                                .read<CartBloc>()
                                .add(CartItemQuantityIncreased(item));
                          } // Kết thúc hàm callback
                        : null,
                  ),
                ],
              )
            ],
          ),
        ),
        // Nút xóa (hoặc menu như trong hình)
        IconButton(
          icon: const Icon(Icons.delete_outline, // Icon thùng rác
              color: Colors.redAccent), // Màu đỏ cho dễ nhận biết
          tooltip:
              'Xóa khỏi giỏ hàng', // Chú thích khi giữ chuột lâu (trên web/desktop)
          onPressed: () {
            // Gửi thẳng event xóa khi nhấn nút
            context.read<CartBloc>().add(CartItemRemoved(item));
            // Có thể thêm SnackBar thông báo đã xóa nếu muốn
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text('${item.name} đã được xóa.'), duration: Duration(seconds: 1)),
            // );
          },
        ),
      ],
    );
  }

  // Widget cho nút +/-
  Widget _buildQuantityButton(
      {required BuildContext context,
      required IconData icon,
      required VoidCallback? onPressed}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  // Widget hiển thị phần tổng tiền và nút thanh toán
  Widget _buildSummarySection(
      BuildContext context, CartState state, NumberFormat formatCurrency) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.white, // Hoặc Theme.of(context).cardColor
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 5,
                offset: Offset(0, -2)),
          ],
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16)) // Bo góc nếu muốn
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng (${state.itemCount} sản phẩm):',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                formatCurrency.format(state.totalPrice),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            // Nút chiếm hết chiều rộng
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.items.isEmpty
                  ? null
                  : () {
                      // TODO: Điều hướng đến trang thanh toán
                      print('Navigate to Checkout');
                      final itemsToCheckout =
                          context.read<CartBloc>().state.items;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CheckoutScreen(cartItems: itemsToCheckout),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('THANH TOÁN'),
            ),
          ),
        ],
      ),
    );
  }
}
