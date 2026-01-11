import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../blocs/auth/auth_bloc.dart'; // Lấy state AuthBloc
import '../../../blocs/cart/cart_bloc.dart'; // Để xóa giỏ hàng sau khi đặt hàng
import '../../../config/app_constants.dart';
import '../../../models/cart_item.dart';
import '../../../models/order.dart';
import '../../../models/user.dart'; // Lấy thông tin user để hiển thị địa chỉ (ví dụ)
import '../../../repositories/order_repository.dart'; // Để gọi API tạo đơn hàng
import '../../../repositories/payment_repository.dart';

// Import màn hình OrderSuccess (tạo placeholder nếu chưa có)
// import '../order/order_success_screen.dart';
enum PaymentMethod { cod, vnpay }

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems; // Nhận danh sách item từ CartScreen
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false; // State xử lý loading khi nhấn đặt hàng
  final _noteController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cod;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _launchVnpayUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      print('Could not launch $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không thể mở URL: $url'), // Hiển thị URL lỗi
              backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
      return; // Dừng lại nếu không thể launch
    }
    if (!await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication, // Mở bằng trình duyệt ngoài ứng dụng
    )) {
      // Xử lý lỗi nếu không mở được URL
      print('Could not launch $url');
      if (mounted) {
        // Kiểm tra mounted trước khi dùng context
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể mở cổng thanh toán VNPAY.'),
              backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false); // Dừng loading nếu lỗi mở URL
    } else {
      // Sau khi mở URL, quay về màn hình chính hoặc trang đơn hàng chờ xử lý
      // Không nên xóa giỏ hàng ở đây vì chưa chắc thanh toán thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Đang chuyển đến VNPAY... Vui lòng hoàn tất thanh toán và quay lại ứng dụng sau.')),
        );
        // Pop màn hình checkout, quay về màn hình trước đó (có thể là giỏ hàng hoặc home)
        Navigator.of(context).pop();
        // TODO: Có thể điều hướng đến trang "Lịch sử đơn hàng" để user theo dõi
      }
    }
  }

  // Hàm xử lý khi nhấn nút Đặt hàng
  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
    }); // Bắt đầu loading

    // Lấy OrderRepository và CartBloc từ context
    final orderRepository = context.read<OrderRepository>();
    final cartBloc = context.read<CartBloc>();
    final authState = context.read<AuthBloc>().state; // Kiểm tra đăng nhập
    final paymentRepository = context.read<PaymentRepository>();

    // Kiểm tra lại trạng thái đăng nhập (dù vào đây thường đã đăng nhập)
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đăng nhập để đặt hàng.'),
            backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Chuẩn bị dữ liệu 'items' theo format API yêu cầu
    final List<Map<String, dynamic>> orderItems = widget.cartItems
        .map((item) => {
              'product_id': item.productId,
              'quantity': item.quantity,
              // Không cần gửi giá ở đây, backend sẽ tự lấy giá mới nhất
            })
        .toList();

    // Lấy ghi chú (nếu có)
    final String? note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;
    final int paymentMethodValue =
        _selectedPaymentMethod == PaymentMethod.vnpay ? 1 : 0;
    try {
      final OrderModel createdOrder = await orderRepository.createOrder(
        items: orderItems,
        note: note,
        paymentMethod: paymentMethodValue,
      );
      // Gọi API tạo đơn hàng

      // Đặt hàng thành công
      print('Order placed successfully: ${createdOrder.id}');
      if (_selectedPaymentMethod == PaymentMethod.vnpay) {
        // Nếu là VNPAY, gọi API backend để tạo URL thanh toán
        print('Initiating VNPAY payment for order ${createdOrder.id}');
        try {
          final String paymentUrl = await paymentRepository.createVnpayUrl(
            orderId: createdOrder.id,
            amount: createdOrder.total ?? 0, // Lấy tổng tiền từ đơn hàng đã tạo
            orderDescription: 'Thanh toan don hang ${createdOrder.id}',
            // bankCode: null, // Có thể thêm nếu muốn chọn ngân hàng cụ thể
          );
          // Mở URL VNPAY
          await _launchVnpayUrl(paymentUrl);
          // Loading sẽ được set thành false trong _launchVnpayUrl (hoặc nếu có lỗi)
        } catch (e) {
          // Lỗi khi tạo URL VNPAY
          print('Error creating VNPAY URL: $e');
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Lỗi tạo link thanh toán VNPAY: ${e.toString().replaceFirst('Exception: ', '')}'),
                  backgroundColor: Colors.red),
            );
          }
          // Lưu ý: Đơn hàng đã được tạo ở backend với status 0, cần cơ chế hủy nếu user không thanh toán
        }
      } else {
        // Nếu là COD, xử lý như cũ
        cartBloc.add(CartCleared()); // Xóa giỏ hàng
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          // Kiểm tra mounted trước khi dùng context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đặt hàng COD thành công!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context)
              .popUntil((route) => route.isFirst); // Quay về home
        }
      }
      // Xóa giỏ hàng cục bộ
      cartBloc.add(CartCleared());

      setState(() {
        _isLoading = false;
      }); // Kết thúc loading

      // Điều hướng đến màn hình đặt hàng thành công (hoặc trang lịch sử đơn hàng)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đặt hàng thành công!'),
            backgroundColor: Colors.green),
      );
      // Ví dụ: Quay về màn hình gốc và xóa các màn hình trung gian (Cart, Checkout)
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Hoặc Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: createdOrder)));
    } catch (e) {
      // Xử lý lỗi đặt hàng
      print('Error placing order: $e');
      setState(() {
        _isLoading = false;
      }); // Kết thúc loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Đặt hàng thất bại: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Tính tổng tiền từ cartItems truyền vào
    final totalPrice = widget.cartItems
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
    // Lấy thông tin user để hiển thị địa chỉ (ví dụ)
    UserModel? currentUser;
    final authState = context.watch<AuthBloc>().state; // Dùng watch để lấy user
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Mục Địa chỉ giao hàng ---
            Text('Địa chỉ giao hàng',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: currentUser != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${currentUser.name} | ${currentUser.phone ?? "Chưa có SĐT"}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                // TODO: Thêm địa chỉ chi tiết của user nếu có trong model User
                                Text(currentUser.email), // Tạm dùng email
                              ],
                            )
                          : const Text('Không tìm thấy thông tin người dùng.'),
                    ),
                    // TODO: Thêm nút "Thay đổi" địa chỉ
                  ],
                ),
              ),
            ),
            const Divider(height: 32),

            // --- Mục Sản phẩm ---
            Text('Sản phẩm', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap:
                  true, // Quan trọng khi đặt ListView trong SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // Không cho ListView này cuộn
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                // Hiển thị thông tin item (không cho sửa số lượng ở đây)
                return ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: item.image != null
                          ? Image.network(AppConstants.baseUrl + item.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.image))
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                  title: Text(item.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatCurrency.format(item.price)),
                  trailing: Text('x ${item.quantity}'),
                );
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 8, indent: 66), // Kẻ ngang ngắn
            ),
            const Divider(height: 32),

            // --- Phương thức thanh toán ---
            Text('Phương thức thanh toán',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  RadioListTile<PaymentMethod>(
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    value: PaymentMethod.cod,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                    secondary:
                        const Icon(Icons.local_shipping_outlined), // Icon COD
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(
                      height: 1, indent: 16, endIndent: 16), // Ngăn cách
                  RadioListTile<PaymentMethod>(
                    title: const Text('Thanh toán qua VNPAY'),
                    subtitle: const Text('Thanh toán VNPay'), // Thêm mô tả
                    value: PaymentMethod.vnpay,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                    secondary: Image.asset(
                      // << Thêm logo VNPAY (cần có ảnh trong assets)
                      'assets/images/vnpay_logo.png', // << Đảm bảo có ảnh này
                      height: 24, // Kích thước logo
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.payment), // Icon dự phòng
                    ),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),

            // --- Địa chỉ ---
            Text('Địa chỉ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ giao hàng cho người bán ...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),

            // Thêm các phần khác nếu cần (voucher, tổng kết chi tiết hơn...)
          ],
        ),
      ),
      // --- Phần Bottom: Tổng tiền và Nút Đặt hàng ---
      bottomNavigationBar:
          _buildCheckoutButtonSection(context, formatCurrency, totalPrice),
    );
  }

  // Widget cho phần tổng tiền và nút đặt hàng ở dưới
  Widget _buildCheckoutButtonSection(
      BuildContext context, NumberFormat formatCurrency, int totalPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
          .copyWith(
              bottom: MediaQuery.of(context).padding.bottom +
                  12.0), // An toàn với vùng dưới
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 5,
              offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tổng tiền
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng thanh toán:',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                formatCurrency.format(totalPrice),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Nút Đặt hàng
          ElevatedButton(
            onPressed:
                _isLoading ? null : _placeOrder, // Vô hiệu hóa khi đang loading
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Đặt hàng'),
          ),
        ],
      ),
    );
  }
}
