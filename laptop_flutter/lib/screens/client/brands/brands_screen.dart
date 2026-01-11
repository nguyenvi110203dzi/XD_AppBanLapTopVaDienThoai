import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/screens/client/brands/products_by_brand_screen.dart';

import '../../../blocs/brand/brand_bloc.dart';
import '../../../config/app_constants.dart';
// Import trang sản phẩm theo brand

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange, // Màu nền trắng như hình
        foregroundColor: Colors.black, // Chữ màu đen
        elevation: 1, // Thêm đường viền mờ nếu muốn
        title: const Text('Thương Hiệu'),
      ),
      body: BlocBuilder<BrandBloc, BrandState>(
        builder: (context, state) {
          if (state is BrandLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrandError) {
            return Center(child: Text('Lỗi tải thương hiệu: ${state.message}'));
          }
          if (state is BrandLoaded) {
            if (state.brands.isEmpty) {
              return const Center(child: Text('Không có thương hiệu nào.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: state.brands.length,
              itemBuilder: (context, index) {
                final brand = state.brands[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  clipBehavior: Clip.antiAlias,
                  elevation: 1,
                  child: InkWell(
                    onTap: () {
                      print('Tapped on brand: ${brand.name}');
                      // Điều hướng đến trang sản phẩm theo brand
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductsByBrandScreen(brand: brand),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0), // Tăng padding
                      child: brand.image != null
                          ? Image.network(
                              AppConstants.baseUrl + brand.image!,
                              height: 50, // Điều chỉnh chiều cao logo nếu cần
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                      child: Text(brand.name,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold))),
                            )
                          : Center(
                              child: Text(brand.name,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight
                                          .bold))), // Hiển thị tên nếu không có ảnh
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Trạng thái không xác định'));
        },
      ),
    );
  }
}
