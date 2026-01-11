import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/screens/client/categories/products_by_category_screen.dart';

import '../../../blocs/category/category_bloc.dart';
import '../../../config/app_constants.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Mục Sản Phẩm'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoryError) {
            return Center(child: Text('Lỗi tải danh mục: ${state.message}'));
          }
          if (state is CategoryLoaded) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('Không có danh mục nào.'));
            }
            // Sử dụng ListView.separated để có dòng kẻ phân cách
            return ListView.separated(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return ListTile(
                  leading: category.image != null
                      ? Image.network(AppConstants.baseUrl + category.image!,
                          width: 300,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.category))
                      : const Icon(Icons.category_outlined),
                  onTap: () {
                    print('Tapped on category: ${category.name}');
                    // Điều hướng đến trang sản phẩm theo category
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductsByCategoryScreen(category: category),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) =>
                  const Divider(height: 1), // Dòng kẻ phân cách
            );
          }
          return const Center(child: Text('Trạng thái không xác định'));
        },
      ),
    );
  }
}
