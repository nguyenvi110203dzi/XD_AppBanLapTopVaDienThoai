import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/search/search_bloc.dart';
import '../../../repositories/product_repository.dart'; // Cần để tạo Bloc
import '../../../widgets/product_card.dart'; // Dùng lại ProductCard
import '../product/product_detail_screen.dart'; // Để điều hướng khi nhấn vào card

class SearchResultScreen extends StatelessWidget {
  final String searchTerm;

  const SearchResultScreen({super.key, required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Tạo SearchBloc ngay tại đây, chỉ dùng cho màn hình này
      create: (context) => SearchBloc(
        productRepository:
            context.read<ProductRepository>(), // Lấy repo từ context cha
      )..add(PerformSearch(searchTerm)), // Gửi event tìm kiếm ngay khi tạo Bloc
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kết quả cho: "$searchTerm"'),
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading) {
              return const Center(
                  child: CircularProgressIndicator()); // Hiển thị loading
            }
            if (state is SearchError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Lỗi tìm kiếm: ${state.message}'),
                ),
              );
            }
            if (state is SearchEmpty) {
              return const Center(
                child: Text('Không tìm thấy sản phẩm nào phù hợp.'),
              );
            }
            if (state is SearchLoaded) {
              // Hiển thị kết quả dạng GridView
              return GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 sản phẩm trên một dòng
                  childAspectRatio: 0.75, // Điều chỉnh tỉ lệ nếu cần
                  crossAxisSpacing: 10, // Khoảng cách giữa các card
                  mainAxisSpacing: 10, // Khoảng cách dọc giữa các card
                ),
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  final product = state.results[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      // Điều hướng đến chi tiết sản phẩm
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: product.id),
                        ),
                      );
                    },
                  );
                },
              );
            }
            // Trạng thái SearchInitial hoặc không xác định
            return const SizedBox.shrink(); // Không hiển thị gì
          },
        ),
      ),
    );
  }
}
