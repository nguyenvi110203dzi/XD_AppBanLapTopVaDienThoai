// lib/screens/admin/category/admin_category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import BLoC, Repo, Model của Category
import 'package:laptop_flutter/blocs/admin_management/category_management/category_management_bloc.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart';
import 'package:laptop_flutter/repositories/category_repository.dart';

// Import màn hình Add/Edit Category (sẽ tạo ở bước sau)
import 'admin_add_edit_category_screen.dart';

class AdminCategoryManagementScreen extends StatelessWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => CategoryRepository(
        // Cung cấp CategoryRepository
        authRepository: context.read<AuthRepository>(),
      ),
      child: BlocProvider(
        create: (context) => CategoryManagementBloc(
          // Cung cấp CategoryManagementBloc
          categoryRepository: context.read<CategoryRepository>(),
        )..add(LoadCategories()), // Tải danh sách categories
        child: Scaffold(
          body: BlocListener<CategoryManagementBloc, CategoryManagementState>(
            // Lắng nghe CategoryManagementBloc
            listener: (context, state) {
              if (state is CategoryOperationSuccess) {
                // State thành công
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green),
                  );
              } else if (state is CategoryOperationFailure) {
                // State thất bại
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                        content: Text('Lỗi: ${state.error}'),
                        backgroundColor: Colors.red),
                  );
              }
            },
            child: BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
              // Build UI theo CategoryManagementBloc
              builder: (context, state) {
                if (state is CategoryLoading ||
                    state is CategoryOperationInProgress &&
                        state is! CategoryLoadSuccess) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CategoryLoadSuccess) {
                  // State tải thành công
                  final categories =
                      state.categories; // Lấy danh sách categories
                  if (categories.isEmpty) {
                    return const Center(
                        child:
                            Text('Không có danh mục nào.')); // Thông báo rỗng
                  }
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index]; // Lấy từng category
                      return ListTile(
                        leading: category.image != null &&
                                category.image!.isNotEmpty
                            ? Image.network(
                                context
                                        .read<CategoryRepository>()
                                        .authRepository
                                        .baseUrl +
                                    category.image!, // Hiển thị ảnh
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, size: 40),
                              )
                            : const Icon(Icons.category_outlined,
                                size: 40), // Icon mặc định
                        title: Text(category.name), // Tên danh mục
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Builder(builder: (buttonContext) {
                              return IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(
                                    buttonContext,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: BlocProvider.of<
                                                CategoryManagementBloc>(
                                            buttonContext), // Chia sẻ BLoC
                                        child: AdminAddEditCategoryScreen(
                                            category:
                                                category), // Điều hướng sửa
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                            Builder(builder: (buttonContext) {
                              return IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(buttonContext,
                                      category.id); // Gọi dialog xóa
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is CategoryLoadFailure) {
                  // State tải thất bại
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi tải danh sách danh mục: ${state.error}'),
                        const SizedBox(height: 10),
                        Builder(builder: (buttonContext) {
                          return ElevatedButton(
                            onPressed: () => buttonContext
                                .read<CategoryManagementBloc>()
                                .add(LoadCategories()), // Thử lại
                            child: const Text('Thử lại'),
                          );
                        })
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Đang tải...'));
              },
            ),
          ),
          floatingActionButton: Builder(builder: (buttonContext) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  buttonContext,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: BlocProvider.of<CategoryManagementBloc>(
                          buttonContext), // Chia sẻ BLoC
                      child:
                          const AdminAddEditCategoryScreen(), // Điều hướng thêm mới
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Thêm danh mục', // Tooltip
            );
          }),
        ),
      ),
    );
  }

// Hàm hiển thị dialog xác nhận xóa
  void _showDeleteConfirmationDialog(
      BuildContext buttonContext, int categoryId) {
    showDialog(
      context: buttonContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa danh mục này không? Nếu danh mục có sản phẩm liên kết, việc xóa có thể không thành công.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                // Gửi event xóa đến BLoC
                buttonContext
                    .read<CategoryManagementBloc>()
                    .add(DeleteCategory(id: categoryId)); // Event xóa category
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
