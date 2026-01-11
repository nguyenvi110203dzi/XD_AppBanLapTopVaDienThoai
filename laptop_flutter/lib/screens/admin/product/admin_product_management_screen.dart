import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Για định dạng tiền tệ
import 'package:laptop_flutter/models/product.dart';

// --- Import các file cần thiết ---
import '../../../blocs/admin_management/product_management/product_management_bloc.dart';
import '../../../repositories/auth_repository.dart'; // Cần để lấy baseUrl
import '../../../repositories/brand_repository.dart'; // Cần để tạo ProductManagementBloc
import '../../../repositories/category_repository.dart'; // Cần để tạo ProductManagementBloc
import '../../../repositories/product_repository.dart';
import 'admin_add_edit_product_screen.dart';
// ---------------------------------

class AdminProductManagementScreen extends StatelessWidget {
  const AdminProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    // Lấy baseUrl từ AuthRepository để hiển thị ảnh
    // Đảm bảo AuthRepository được cung cấp ở main.dart
    final String baseUrl = context.read<AuthRepository>().baseUrl;

    return BlocProvider(
      create: (context) => ProductManagementBloc(
        // Lấy các Repo đã được cung cấp ở main.dart
        productRepository: context.read<ProductRepository>(),
        brandRepository: context.read<BrandRepository>(),
        categoryRepository: context.read<CategoryRepository>(),
      )..add(LoadAdminProducts()), // Load dữ liệu khi tạo Bloc
      child: Scaffold(
        body: BlocListener<ProductManagementBloc, ProductManagementState>(
          listener: (context, state) {
            // Hiển thị SnackBar cho các thao tác thành công/thất bại
            if (state is ProductManagementOperationSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green));
            } else if (state is ProductManagementOperationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Lỗi: ${state.error}"),
                    backgroundColor: Colors.red));
            }
          },
          child: BlocBuilder<ProductManagementBloc, ProductManagementState>(
            builder: (context, state) {
              // 1. Trạng thái Loading
              if (state is ProductManagementLoading &&
                  state is! ProductManagementOperationFailure &&
                  state is! ProductManagementOperationSuccess) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Trạng thái Lỗi tải ban đầu
              if (state is ProductManagementFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi tải danh sách sản phẩm: ${state.error}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ProductManagementBloc>()
                              .add(LoadAdminProducts()),
                          child: const Text('Thử lại'),
                        )
                      ],
                    ),
                  ),
                );
              }

              // 3. Trạng thái Loaded hoặc sau Operation
              List<ProductModel> products = [];
              if (state is ProductManagementLoaded) {
                products = state.products;
              } else {
                // Cố gắng lấy state cũ nếu là lỗi operation
                final currentState =
                    context.read<ProductManagementBloc>().state;
                if (currentState is ProductManagementLoaded) {
                  products = currentState.products;
                } else {
                  // Không có dữ liệu cũ, hiện loading chờ load lại
                  return const Center(child: CircularProgressIndicator());
                }
              }

              // Hiển thị nếu danh sách rỗng
              if (products.isEmpty && state is ProductManagementLoaded) {
                return const Center(child: Text('Chưa có sản phẩm nào.'));
              } else if (products.isEmpty &&
                  state is! ProductManagementLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- Hiển thị ListView ---
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ProductManagementBloc>()
                      .add(LoadAdminProducts());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final imageUrl =
                        (product.image != null && product.image!.isNotEmpty)
                            ? (Uri.tryParse(product.image!)?.isAbsolute ?? false
                                ? product.image!
                                : (baseUrl.isNotEmpty
                                    ? (baseUrl.endsWith('/')
                                            ? baseUrl.substring(
                                                0, baseUrl.length - 1)
                                            : baseUrl) +
                                        (product.image!.startsWith('/')
                                            ? product.image!
                                            : '/${product.image!}')
                                    : null))
                            : null;
                    final isValidImageUrl = imageUrl != null &&
                        (Uri.tryParse(imageUrl)?.isAbsolute ?? false);

                    return Card(
                      clipBehavior: Clip.antiAlias, // Bo góc cho cả Card
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              // Đặt ảnh trong Container để dễ tùy chỉnh
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: isValidImageUrl
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover, // Cover để lấp đầy
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null));
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                            ),
                            title: Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatCurrency.format(product.price),
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w600)),
                                if (product.oldprice != null &&
                                    product.oldprice! > 0)
                                  Text(formatCurrency.format(product.oldprice),
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey)),
                                Text('SL: ${product.quantity}'),
                                Text(
                                    'Thương hiệu: ${product.brand?.name ?? 'N/A'}'), // Hiển thị tên Brand (nếu có)
                                Text(
                                    'Danh mục: ${product.category?.name ?? 'N/A'}'), // Hiển thị tên Category (nếu có)
                              ],
                            ),
                            isThreeLine:
                                true, // Cho phép subtitle hiển thị nhiều dòng
                          ),
                          // Dải nút thao tác
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Sửa'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.blueAccent),
                                  onPressed: () {
                                    final productBloc =
                                        context.read<ProductManagementBloc>();
                                    print("Edit product ${product.id}");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminAddEditProductScreen(
                                          productToEdit:
                                              product, // Truyền sản phẩm cần sửa
                                          productManagementBloc:
                                              productBloc, // <<< TRUYỀN BLOC VÀO ĐÂY
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Xóa'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        context, product);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8), // Khoảng cách nhỏ dưới nút
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: Builder(
          builder: (buttonContext) => FloatingActionButton.extended(
            onPressed: () {
              final productBloc = buttonContext.read<ProductManagementBloc>();
              print("Add new product");
              Navigator.push(
                buttonContext, // Dùng context của nút
                MaterialPageRoute(
                  builder: (_) => AdminAddEditProductScreen(
                    // Không truyền productToEdit
                    productManagementBloc:
                        productBloc, // <<< TRUYỀN BLOC VÀO ĐÂY
                  ),
                ),
              );
              ;
            },
            label: const Text('Thêm SP'),
            icon: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  // --- Dialog Xác nhận Xóa Sản phẩm ---
  void _showDeleteConfirmationDialog(
      BuildContext context, ProductModel product) {
    final bloc = BlocProvider.of<ProductManagementBloc>(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                bloc.add(DeleteProduct(productId: product.id));
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
