import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/models/product.dart';
import 'package:laptop_flutter/repositories/product_repository.dart'; // Để lấy tất cả sản phẩm
import 'package:laptop_flutter/screens/client/product/product_detail_screen.dart';
import 'package:laptop_flutter/widgets/product_card.dart'; // Dùng lại ProductCard nếu phù hợp

import 'create_credit_order_screen.dart';

class CreditProductListScreen extends StatefulWidget {
  const CreditProductListScreen({super.key});

  @override
  State<CreditProductListScreen> createState() =>
      _CreditProductListScreenState();
}

class _CreditProductListScreenState extends State<CreditProductListScreen> {
  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<ProductModel> _selectedProducts = [];
  final Map<int, int> _selectedQuantities = {}; // productId -> quantity

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await context.read<ProductRepository>().getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi tải danh sách sản phẩm: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  void _toggleProductSelection(ProductModel product) {
    setState(() {
      final isSelected = _selectedProducts.any((p) => p.id == product.id);
      if (isSelected) {
        _selectedProducts.removeWhere((p) => p.id == product.id);
        _selectedQuantities.remove(product.id);
      } else {
        // Kiểm tra số lượng tồn kho của sản phẩm trước khi thêm
        // Mặc dù API không giới hạn, nhưng việc hiển thị số lượng 0 cho khách có thể gây nhầm lẫn
        // Nếu backend cho phép số lượng âm thì không cần kiểm tra này.
        // if (product.quantity > 0) { // Bỏ qua nếu số lượng tồn là 0
        _selectedProducts.add(product);
        _selectedQuantities[product.id] = 1; // Mặc định số lượng là 1
        // } else {
        //      ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(content: Text('${product.name} hiện đang hết hàng.')),
        //     );
        // }
      }
    });
  }

  void _updateQuantity(ProductModel product, int newQuantity) {
    if (newQuantity <= 0) {
      setState(() {
        _selectedProducts.removeWhere((p) => p.id == product.id);
        _selectedQuantities.remove(product.id);
      });
      return;
    }
    // API backend cho phép số lượng âm khi mua công nợ, nên không cần giới hạn bởi product.quantity
    setState(() {
      _selectedQuantities[product.id] = newQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mua Hàng Công Nợ'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_selectedProducts.length}'),
              isLabelVisible: _selectedProducts.isNotEmpty,
              child: const Icon(Icons.playlist_add_check_circle_outlined),
            ),
            tooltip: 'Xem đơn hàng công nợ',
            onPressed: _selectedProducts.isEmpty
                ? null
                : () {
                    if (_selectedProducts
                        .any((p) => (_selectedQuantities[p.id] ?? 0) <= 0)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Vui lòng chọn số lượng lớn hơn 0 cho tất cả sản phẩm.'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateCreditOrderScreen(
                          selectedProducts:
                              List.from(_selectedProducts), // Tạo bản sao
                          selectedQuantities:
                              Map.from(_selectedQuantities), // Tạo bản sao
                        ),
                      ),
                    ).then((orderCreatedSuccessfully) {
                      if (orderCreatedSuccessfully == true && mounted) {
                        setState(() {
                          _selectedProducts.clear();
                          _selectedQuantities.clear();
                        });
                      }
                    });
                  },
          ),
        ],
      ),
      body: _buildProductList(),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, textAlign: TextAlign.center),
      ));
    }
    if (_allProducts.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nào để hiển thị.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio:
            0.65, // Tăng chiều cao để có thêm không gian cho nút số lượng
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _allProducts.length,
      itemBuilder: (context, index) {
        final product = _allProducts[index];
        final isSelected = _selectedProducts.any((p) => p.id == product.id);
        final quantity = _selectedQuantities[product.id] ?? 0;

        // Không hiển thị sản phẩm có quantity = 0 nếu không muốn khách hàng công nợ đặt
        // if (product.quantity <= 0 && !isSelected) {
        //   return const SizedBox.shrink(); // Hoặc hiển thị mờ đi
        // }

        return Card(
          elevation: isSelected ? 4 : 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColorDark
                  : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _toggleProductSelection(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3, // Tỷ lệ cho phần ảnh và thông tin cơ bản
                  child: Stack(
                    children: [
                      Padding(
                        // Bọc ProductCard bằng Padding để có không gian cho Checkbox
                        padding: const EdgeInsets.all(4.0),
                        child: ProductCard(
                            product: product,
                            onTap: () {
                              // Khi nhấn vào ProductCard (không phải nút chọn), thì xem chi tiết SP
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                        productId: product.id)),
                              );
                            }),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      // Không hiển thị "Hết hàng" cho khách sỉ ở màn hình này
                      // vì họ có thể đặt hàng với số lượng âm
                    ],
                  ),
                ),
                // Phần điều chỉnh số lượng chỉ hiển thị khi sản phẩm được chọn
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      // borderRadius: const BorderRadius.only(
                      //   bottomLeft: Radius.circular(10),
                      //   bottomRight: Radius.circular(10),
                      // )
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.remove_circle_outline, size: 26),
                          onPressed: () =>
                              _updateQuantity(product, quantity - 1),
                          color: Colors.red.shade400,
                          tooltip: "Giảm",
                        ),
                        Text('$quantity',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 26),
                          onPressed: () =>
                              _updateQuantity(product, quantity + 1),
                          color: Colors.green.shade600,
                          tooltip: "Tăng",
                        ),
                      ],
                    ),
                  )
                else
                  // Nút "Chọn mua" nếu chưa được chọn
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Chọn mua'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => _toggleProductSelection(product),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
