import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart'; // Cần để inject vào Repo
import 'package:laptop_flutter/repositories/brand_repository.dart';

import '../../../blocs/admin_management/brand_management/brand_management_bloc.dart';
import 'admin_add_edit_brand_screen.dart'; // Import Repo

// TODO: Import màn hình Add/Edit Brand khi tạo xong
// import 'admin_add_edit_category_screen.dart';

class AdminBrandManagementScreen extends StatelessWidget {
  const AdminBrandManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp BrandRepository và BrandBloc
    return RepositoryProvider(
      create: (context) => BrandRepository(
        authRepository: context.read<
            AuthRepository>(), // Lấy AuthRepo đã được cung cấp ở đâu đó bên trên (ví dụ: main.dart)
      ),
      child: BlocProvider(
        create: (context) => BrandManagementBloc(
          brandRepository: context.read<BrandRepository>(),
        )..add(LoadBrands()), // Tải danh sách brands khi màn hình được tạo
        child: Scaffold(
          // Không cần AppBar ở đây vì AdminMainScreen đã có AppBar chung
          body: BlocListener<BrandManagementBloc, BrandManagementState>(
            listener: (context, state) {
              // Hiển thị thông báo cho các thao tác thành công hoặc thất bại
              if (state is BrandOperationSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green),
                  );
              } else if (state is BrandOperationFailure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: ${state.error}'),
                        backgroundColor: Colors.red),
                  );
              }
            },
            child: BlocBuilder<BrandManagementBloc, BrandManagementState>(
              builder: (context, state) {
                if (state is BrandLoading ||
                    state is BrandOperationInProgress &&
                        state is! BrandLoadSuccess) {
                  // Hiển thị loading nếu đang tải lần đầu hoặc đang thực hiện thao tác mà chưa có dữ liệu cũ
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BrandLoadSuccess) {
                  // Hiển thị danh sách brands
                  final brands = state.brands;
                  if (brands.isEmpty) {
                    return const Center(
                        child: Text('Không có thương hiệu nào.'));
                  }
                  return ListView.builder(
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      // TODO: Thay thế bằng ListTile hoặc Card tùy chỉnh đẹp hơn
                      return ListTile(
                        // Hiển thị ảnh nếu có
                        leading: brand.image != null && brand.image!.isNotEmpty
                            ? Image.network(
                                // TODO: Ghép base URL vào đây nếu cần
                                context
                                        .read<BrandRepository>()
                                        .authRepository
                                        .baseUrl +
                                    brand.image!,
                                width: 120,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, size: 40),
                              )
                            : const Icon(Icons.storefront,
                                size: 40), // Icon mặc định
                        title: Text(brand.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(builder: (context) {
                              return IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () {
                                  // TODO: Điều hướng đến màn hình Edit với brand.id và thông tin brand
                                  print('Edit brand: ${brand.id}');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        // Cung cấp instance BLoC hiện tại cho màn hình Add/Edit
                                        value: BlocProvider.of<
                                                BrandManagementBloc>(
                                            context), // Lấy BLoC từ context hiện tại
                                        child: AdminAddEditBrandScreen(
                                            brand:
                                                brand), // Truyền brand để sửa
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Hiển thị dialog xác nhận xóa
                                _showDeleteConfirmationDialog(
                                    context, brand.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is BrandLoadFailure) {
                  // Hiển thị lỗi tải danh sách
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi tải danh sách thương hiệu: ${state.error}'),
                        const SizedBox(height: 10),
                        Builder(builder: (context) {
                          return ElevatedButton(
                            onPressed: () => context
                                .read<BrandManagementBloc>()
                                .add(LoadBrands()),
                            child: const Text('Thử lại'),
                          );
                        })
                      ],
                    ),
                  );
                }
                // Trạng thái khởi tạo hoặc không xác định
                return const Center(child: Text('Đang tải...'));
              },
            ),
          ),
          floatingActionButton: Builder(builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                // TODO: Điều hướng đến màn hình Add (không truyền brand)
                print('Add new brand');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      // Cung cấp instance BLoC hiện tại cho màn hình Add/Edit
                      value: BlocProvider.of<BrandManagementBloc>(
                          context), // Lấy BLoC từ context hiện tại
                      child:
                          const AdminAddEditBrandScreen(), // Không truyền brand (thêm mới)
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Thêm thương hiệu',
            );
          }),
        ),
      ),
    );
  }

  // Hàm hiển thị dialog xác nhận xóa
  void _showDeleteConfirmationDialog(BuildContext context, int brandId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa thương hiệu này không? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                // Gửi event xóa đến BLoC
                context
                    .read<BrandManagementBloc>()
                    .add(DeleteBrand(id: brandId));
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
            ),
          ],
        );
      },
    );
  }
}
