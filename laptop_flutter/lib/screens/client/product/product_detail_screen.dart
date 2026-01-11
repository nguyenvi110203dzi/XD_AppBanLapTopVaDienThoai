import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart'; // Import flutter_html
import 'package:intl/intl.dart'; // Import intl
import 'package:laptop_flutter/models/product.dart';

import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/product_detail/product_detail_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../repositories/product_repository.dart'; // Cần để khởi tạo Bloc

class ProductDetailScreen extends StatelessWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  Widget _buildSpecRow(String label, String? value) {
    if (value == null || value.isEmpty || value.trim() == 'N/A') {
      // Bỏ qua nếu null, rỗng hoặc 'N/A'
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần Label (in đậm)
          SizedBox(
            width: 140, // Đặt chiều rộng cố định cho label để căn chỉnh
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w600), // Đậm hơn một chút
            ),
          ),
          const SizedBox(width: 8), // Khoảng cách giữa label và value
          // Phần Value (linh hoạt)
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRowBool(String label, bool? value) {
    if (value == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value ? 'Có' : 'Không'), // Hiển thị Có/Không
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          top: 16.0, bottom: 8.0), // Thêm khoảng cách trên dưới
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17, // Cỡ chữ lớn hơn cho tiêu đề
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent, // Màu sắc nổi bật
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp ProductDetailBloc cho màn hình này
    // Lấy repository từ context cha (đã cung cấp ở main.dart)
    return BlocProvider(
      create: (context) => ProductDetailBloc(
        productRepository: context.read<ProductRepository>(),
        // Cung cấp các repo khác nếu cần load feedback, related products
      )..add(LoadProductDetail(productId)), // Gọi event load dữ liệu ngay
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin sản phẩm'),
        ),
        body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is ProductDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    // Hiển thị lỗi rõ ràng hơn
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text('Lỗi tải dữ liệu:',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 5),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        onPressed: () {
                          // Gửi lại event LoadProductDetail khi nhấn nút thử lại
                          context
                              .read<ProductDetailBloc>()
                              .add(LoadProductDetail(productId));
                        },
                      )
                    ],
                  ),
                ),
              );
            }
            if (state is ProductDetailLoaded) {
              final product = state.product;
              final formatCurrency =
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
              bool onSale =
                  product.oldprice != null && product.oldprice! > product.price;

              return SingleChildScrollView(
                // Cho phép cuộn toàn bộ nội dung
                padding: const EdgeInsets.only(
                    bottom:
                        80), // Thêm padding dưới cùng để nút không che nội dung
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0), // Padding chung
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Hình ảnh sản phẩm ---
                      Card(
                        // Bọc ảnh trong Card để có hiệu ứng đổ bóng nhẹ
                        elevation: 2,
                        clipBehavior: Clip.antiAlias, // Cắt góc tròn cho ảnh
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                          child: product.image != null
                              ? Image.network(
                                  AppConstants.baseUrl + product.image!,
                                  fit: BoxFit
                                      .contain, // Contain để thấy toàn bộ ảnh
                                  height: 300,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      // Placeholder khi ảnh đang tải
                                      height: 300,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    // Placeholder khi lỗi ảnh
                                    height: 300,
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            size: 60, color: Colors.grey)),
                                  ),
                                )
                              : Container(
                                  // Placeholder khi không có ảnh
                                  height: 300,
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 60,
                                          color: Colors.grey)),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- Tên sản phẩm ---
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.3), // Tăng chiều cao dòng
                      ),
                      const SizedBox(height: 10),

                      // --- Giá sản phẩm ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Căn giữa theo chiều dọc
                        children: [
                          Text(
                            formatCurrency.format(product.price),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 26, // Giá chính to hơn
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (onSale)
                            Text(
                              formatCurrency.format(product.oldprice),
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 18, // Giá cũ nhỏ hơn chút
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Divider(thickness: 1), // Đường kẻ ngang phân cách

                      // --- Phần hiển thị thông số kỹ thuật chi tiết ---
                      _buildSectionTitle('Thông số kỹ thuật chi tiết'),

                      // Card chứa thông tin cấu hình
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cấu hình & Bộ nhớ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87)),
                              const Divider(height: 15),
                              if (product.cauhinhBonho != null) ...[
                                _buildSpecRow('Hệ điều hành',
                                    product.cauhinhBonho!.hedieuhanh),
                                _buildSpecRow('Chip xử lý (CPU)',
                                    product.cauhinhBonho!.chipCPU),
                                _buildSpecRow('Tốc độ CPU',
                                    product.cauhinhBonho!.tocdoCPU),
                                _buildSpecRow('Chip đồ họa (GPU)',
                                    product.cauhinhBonho!.chipDohoa),
                                _buildSpecRow('RAM', product.cauhinhBonho!.ram),
                                _buildSpecRow('Dung lượng lưu trữ',
                                    product.cauhinhBonho!.dungluongLuutru),
                                _buildSpecRow('Dung lượng khả dụng',
                                    product.cauhinhBonho!.dungluongKhadung),
                                _buildSpecRow('Thẻ nhớ ngoài',
                                    product.cauhinhBonho!.thenho),
                                _buildSpecRow(
                                    'Danh bạ', product.cauhinhBonho!.danhba),
                              ] else
                                const Text('Không có thông tin cấu hình.',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                      // Card chứa thông tin Camera & Màn hình
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Camera & Màn hình',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87)),
                              const Divider(height: 15),
                              if (product.cameraManhinh != null) ...[
                                _buildSpecRow('Camera sau',
                                    product.cameraManhinh!.dophangiaiCamsau),
                                _buildSpecRow('Công nghệ cam sau',
                                    product.cameraManhinh!.congngheCamsau),
                                _buildSpecRowBool('Đèn Flash',
                                    product.cameraManhinh!.denflashCamsau),
                                _buildSpecRow('Tính năng cam sau',
                                    product.cameraManhinh!.tinhnangCamsau),
                                _buildSpecRow('Camera trước',
                                    product.cameraManhinh!.dophangiaiCamtruoc),
                                _buildSpecRow('Tính năng cam trước',
                                    product.cameraManhinh!.tinhnangCamtruoc),
                                _buildSpecRow('Công nghệ màn hình',
                                    product.cameraManhinh!.congngheManhinh),
                                _buildSpecRow('Độ phân giải',
                                    product.cameraManhinh!.dophangiaiManhinh),
                                _buildSpecRow('Màn hình rộng',
                                    product.cameraManhinh!.rongManhinh),
                                _buildSpecRow('Độ sáng tối đa',
                                    product.cameraManhinh!.dosangManhinh),
                                _buildSpecRow('Mặt kính cảm ứng',
                                    product.cameraManhinh!.matkinhManhinh),
                              ] else
                                const Text(
                                    'Không có thông tin camera/màn hình.',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                      // Card chứa thông tin Pin & Sạc
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pin & Sạc',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87)),
                              const Divider(height: 15),
                              if (product.pinSac != null) ...[
                                _buildSpecRow('Dung lượng pin',
                                    product.pinSac!.dungluongPin),
                                _buildSpecRow(
                                    'Loại pin', product.pinSac!.loaiPin),
                                _buildSpecRow('Hỗ trợ sạc tối đa',
                                    product.pinSac!.hotrosacMax),
                                _buildSpecRow('Sạc kèm theo máy',
                                    product.pinSac!.sacTheomay),
                                _buildSpecRow('Công nghệ pin',
                                    product.pinSac!.congnghePin),
                              ] else
                                const Text('Không có thông tin pin/sạc.',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 10), // Khoảng cách trước phần mô tả
                      const Divider(thickness: 1),

                      // --- Mô tả sản phẩm (Dùng ExpansionTile và Html) ---
                      ExpansionTile(
                        title: _buildSectionTitle(
                            'Mô tả sản phẩm'), // Sử dụng helper title
                        tilePadding:
                            EdgeInsets.zero, // Bỏ padding mặc định của tile
                        initiallyExpanded: false, // Đóng sẵn
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8), // Padding cho nội dung HTML
                        children: [
                          if (product.description != null &&
                              product.description!.isNotEmpty)
                            // Thêm một lớp Container để có thể style thêm nếu cần
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                  color:
                                      Colors.grey[50], // Nền nhẹ cho phần mô tả
                                  borderRadius: BorderRadius.circular(4)),
                              child: Html(
                                data: product.description!,
                                style: {
                                  "body": Style(
                                    margin: Margins
                                        .zero, // Bỏ margin mặc định của thẻ body trong HTML
                                    fontSize: FontSize(15.0), // Chỉnh cỡ chữ
                                    lineHeight: LineHeight.em(
                                        1.5), // Chỉnh khoảng cách dòng
                                  ),
                                  "p": Style(
                                      margin: Margins.only(
                                          bottom:
                                              10)), // Khoảng cách giữa các đoạn văn
                                  "img": Style(
                                      // Style cho ảnh trong mô tả
                                      width: Width.auto(), // Chiều rộng tự động
                                      margin: Margins.symmetric(
                                          vertical:
                                              10) // Khoảng cách trên dưới ảnh
                                      ),
                                  // Thêm các style khác cho thẻ HTML nếu cần (h1, h2, ul, li,...)
                                },
                              ),
                            )
                          else
                            const Padding(
                              // Padding cho text "Không có mô tả"
                              padding: EdgeInsets.all(16.0),
                              child: Text('Không có mô tả cho sản phẩm này.',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey)),
                            ),
                        ],
                      ),
                      const Divider(height: 1), // Đường kẻ dưới cùng (trên nút)
                    ],
                  ),
                ),
              );
            }
            return const Center(
                child: Text(
                    'Trạng thái không xác định.')); // Trạng thái không xác định
          },
        ),
        bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          // buildWhen chỉ build lại khi state là Loading hoặc Loaded để lấy thông tin product
          buildWhen: (previous, current) =>
              current is ProductDetailLoading || current is ProductDetailLoaded,
          builder: (context, state) {
            bool isLoading =
                state is ProductDetailLoading; // Kiểm tra có đang loading không
            bool isProductAvailable = false; // Mặc định là không có sẵn
            ProductModel? product; // Biến để lấy thông tin product nếu có
            String buttonText = 'Thêm vào giỏ hàng'; // Text mặc định
            IconData buttonIcon = Icons.add_shopping_cart; // Icon mặc định

            if (state is ProductDetailLoaded) {
              product = state.product;
              // Sản phẩm có sẵn nếu số lượng > 0
              isProductAvailable = product.quantity > 0;
              if (!isProductAvailable) {
                buttonText = 'Hết hàng'; // Đổi text nếu hết hàng
                buttonIcon =
                    Icons.remove_shopping_cart; // Đổi icon nếu hết hàng
              }
            } else if (isLoading) {
              buttonText = 'Đang tải...'; // Text khi đang loading
              buttonIcon = Icons.hourglass_empty_rounded;
            }
            // Nút bị vô hiệu hóa khi: đang loading HOẶC sản phẩm không có sẵn
            bool isButtonEnabled = !isLoading && isProductAvailable;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5)
                  ]),
              child: ElevatedButton.icon(
                icon: Icon(buttonIcon), // Icon thay đổi theo trạng thái
                label: Text(buttonText), // Text thay đổi theo trạng thái
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  // Đặt màu nền xám nếu nút bị vô hiệu hóa
                  backgroundColor: isButtonEnabled
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    // Bo góc nút
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: isButtonEnabled ? 2 : 0,
                ),
                // onPressed là null nếu nút bị vô hiệu hóa
                onPressed: isButtonEnabled
                    ? () {
                        // Chỉ thực hiện khi nút được phép nhấn
                        // Kiểm tra lại product null (dù isButtonEnabled đã đảm bảo state là Loaded)
                        if (product != null) {
                          context.read<CartBloc>().add(CartItemAdded(product));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${product.name} đã được thêm vào giỏ hàng.'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                  bottom: kBottomNavigationBarHeight + 10,
                                  left: 15,
                                  right: 15),
                            ),
                          );
                        }
                      }
                    : null, // Nút bị vô hiệu hóa hoàn toàn
              ),
            );
          },
        ),
      ),
    );
  }
}
