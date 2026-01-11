import 'package:flutter/material.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart'; // Import Category model
import '../../../repositories/product_repository.dart';
import '../../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  final Category category; // Nhận Category được chọn

  const ProductsByCategoryScreen({super.key, required this.category});

  @override
  State<ProductsByCategoryScreen> createState() =>
      _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _productsPerPage = 6;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final productRepository = context.read<ProductRepository>();
      // Gọi hàm lấy sản phẩm THEO CATEGORY
      final fetchedProducts =
          await productRepository.getProductsByCategory(widget.category.id);
      setState(() {
        _allProducts = fetchedProducts;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      print("Error fetching products for category ${widget.category.id}: $e");
      setState(() {
        _errorMessage = "Lỗi tải dữ liệu sản phẩm: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  List<ProductModel> _getProductsForCurrentPage() {
    final startIndex = (_currentPage - 1) * _productsPerPage;
    if (startIndex < 0) return [];
    int endIndex = startIndex + _productsPerPage;
    if (endIndex > _allProducts.length) {
      endIndex = _allProducts.length;
    }
    if (startIndex >= _allProducts.length) {
      return [];
    }
    return _allProducts.sublist(startIndex, endIndex);
  }

  int _getTotalPages() {
    if (_allProducts.isEmpty) return 0;
    return (_allProducts.length / _productsPerPage).ceil();
  }

  void _goToNextPage() {
    if (_currentPage < _getTotalPages()) {
      setState(() {
        _currentPage++;
      });
    }
  }

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
        title: Text(widget.category.name), // Tiêu đề là tên Category
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(currentProducts, totalPages),
          ),
          if (totalPages > 1) _buildPaginationControls(totalPages),
        ],
      ),
    );
  }

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
          child: Text('Không có sản phẩm nào cho danh mục này.'));
    }
    if (currentProducts.isEmpty &&
        _currentPage > 1 &&
        totalPages >= _currentPage) {
      return Center(child: Text('Không có sản phẩm cho trang $_currentPage.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: currentProducts.length,
      itemBuilder: (context, index) {
        final product = currentProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
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

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            child: const Icon(Icons.arrow_back),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Trang $_currentPage / $totalPages'),
          ),
          ElevatedButton(
            onPressed: _currentPage < totalPages ? _goToNextPage : null,
            child: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}
