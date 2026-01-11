import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Để lấy repository

import '../../../models/brand.dart';
import '../../../models/product.dart';
import '../../../repositories/product_repository.dart';
import '../../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class ProductsByBrandScreen extends StatefulWidget {
  final Brand brand;

  const ProductsByBrandScreen({super.key, required this.brand});

  @override
  State<ProductsByBrandScreen> createState() => _ProductsByBrandScreenState();
}

class _ProductsByBrandScreenState extends State<ProductsByBrandScreen> {
  List<ProductModel> _allProducts = []; // Lưu tất cả sản phẩm
  bool _isLoading = true; // Trạng thái loading ban đầu
  String? _errorMessage; // Lưu thông báo lỗi nếu có
  int _currentPage = 1; // Trang hiện tại, bắt đầu từ 1
  final int _productsPerPage = 8; // Số sản phẩm mỗi trang (2x3)

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Gọi hàm fetch dữ liệu khi màn hình khởi tạo
  }

  // Hàm gọi API để lấy tất cả sản phẩm theo brand
  Future<void> _fetchProducts() async {
    // Đặt lại trạng thái trước khi fetch
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy ProductRepository từ Provider context
      final productRepository = context.read<ProductRepository>();
      // Gọi API
      final fetchedProducts =
          await productRepository.getProductsByBrand(widget.brand.id);

      // Cập nhật state với dữ liệu mới
      setState(() {
        _allProducts = fetchedProducts;
        _isLoading = false;
        _currentPage = 1; // Reset về trang đầu tiên sau khi fetch thành công
      });
    } catch (e) {
      // Xử lý lỗi
      print("Error fetching products for brand ${widget.brand.id}: $e");
      setState(() {
        _errorMessage = "Lỗi tải dữ liệu sản phẩm: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // Hàm lấy danh sách sản phẩm cho trang hiện tại
  List<ProductModel> _getProductsForCurrentPage() {
    // Tính toán index bắt đầu và kết thúc cho trang hiện tại
    // pageKey là index (bắt đầu từ 0), currentPage là số thứ tự trang (bắt đầu từ 1)
    final startIndex = (_currentPage - 1) * _productsPerPage;
    // Đảm bảo startIndex không âm
    if (startIndex < 0) return [];

    // endIndex không bao gồm phần tử cuối, + _productsPerPage
    int endIndex = startIndex + _productsPerPage;
    // Đảm bảo endIndex không vượt quá độ dài list
    if (endIndex > _allProducts.length) {
      endIndex = _allProducts.length;
    }

    // Tránh lỗi RangeError nếu startIndex >= endIndex (xảy ra khi startIndex >= độ dài list)
    if (startIndex >= _allProducts.length) {
      return []; // Trả về list rỗng nếu trang hiện tại không có sản phẩm
    }

    return _allProducts.sublist(startIndex, endIndex);
  }

  // Tính tổng số trang
  int _getTotalPages() {
    if (_allProducts.isEmpty) return 0;
    // Chia lấy nguyên và cộng 1 nếu có dư
    return (_allProducts.length / _productsPerPage).ceil();
  }

  // Hàm xử lý chuyển trang sau
  void _goToNextPage() {
    if (_currentPage < _getTotalPages()) {
      setState(() {
        _currentPage++;
      });
    }
  }

  // Hàm xử lý chuyển trang trước
  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _getTotalPages();
    final currentProducts = _getProductsForCurrentPage();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brand.name), // Tên thương hiệu làm tiêu đề
      ),
      body: Column(
        // Dùng Column để chứa Grid và nút phân trang
        children: [
          Expanded(
            // GridView chiếm phần không gian còn lại
            child: _buildBody(currentProducts, totalPages),
          ),
          // Chỉ hiển thị nút phân trang nếu có nhiều hơn 1 trang
          if (totalPages > 1) _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

  // Widget xây dựng phần body chính (loading, error, grid)
  Widget _buildBody(List<ProductModel> currentProducts, int totalPages) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_allProducts.isEmpty) {
      return const Center(
          child: Text('Không có sản phẩm nào cho thương hiệu này.'));
    }

    // Hiển thị GridView nếu có sản phẩm cho trang hiện tại
    if (currentProducts.isEmpty &&
        _currentPage > 1 &&
        totalPages >= _currentPage) {
      // Trường hợp này xảy ra nếu tính toán trang có lỗi hoặc dữ liệu không nhất quán
      return Center(child: Text('Không có sản phẩm cho trang $_currentPage.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        childAspectRatio: 1.1, // Tỉ lệ W/H card
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: currentProducts.length,
      itemBuilder: (context, index) {
        final product = currentProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            // Điều hướng đến chi tiết sản phẩm
            print('Navigate to Product Detail: ${product.name}');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ProductDetailScreen(productId: product.id)));
          },
        );
      },
    );
  }

  // Widget xây dựng các nút điều khiển phân trang
  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút Trang trước
          ElevatedButton(
            // Vô hiệu hóa nếu đang ở trang đầu tiên
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            child: const Icon(Icons.arrow_back),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // Hiển thị trang hiện tại / tổng số trang
            child: Text('Trang $_currentPage / $totalPages'),
          ),
          // Nút Trang sau
          ElevatedButton(
            // Vô hiệu hóa nếu đang ở trang cuối cùng
            onPressed: _currentPage < totalPages ? _goToNextPage : null,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
