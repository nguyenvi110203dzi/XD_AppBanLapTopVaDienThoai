import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/home/home_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../models/banner.dart';
import '../../../models/product.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/section_header.dart';
import '../product/product_detail_screen.dart';
import '../search/search_result_screen.dart';
// Import các trang sẽ điều hướng tới
// import '../product/all_products_screen.dart';
// import '../search/search_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false; // State để quản lý trạng thái tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  final CarouselSliderController _bannerController = CarouselSliderController();
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    // Gọi event để tải dữ liệu khi màn hình được khởi tạo
    context.read<HomeBloc>().add(LoadHomeData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn tìm kiếm
  void _handleSearchSubmit(String query) {
    final searchTerm = query.trim(); // Bỏ khoảng trắng thừa
    if (searchTerm.isNotEmpty) {
      setState(() {
        _isSearching = false; // Đóng thanh tìm kiếm lại
        _searchController.clear(); // Xóa nội dung đã nhập
        // Ẩn bàn phím nếu đang hiển thị
        FocusScope.of(context).unfocus();
      });
      // Điều hướng đến trang kết quả tìm kiếm
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SearchResultScreen(searchTerm: searchTerm), // Truyền searchTerm
        ),
      );
    } else {
      // Có thể hiển thị thông báo yêu cầu nhập từ khóa
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập từ khóa tìm kiếm.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Nếu đang tìm kiếm thì hiển thị TextField, ngược lại hiển thị Title
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70)),
                style: const TextStyle(color: Colors.white),
                onSubmitted: _handleSearchSubmit, // Xử lý khi nhấn Enter/Submit
              )
            : const Text('Trang Chủ'),
        actions: [
          // Icon Search/Close
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear(); // Xóa text khi đóng
                }
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  // Nếu vừa đóng search bar -> ẩn bàn phím
                  FocusScope.of(context).unfocus();
                }
              });
            },
          ),
        ],
        backgroundColor: Colors.orange,
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          if (state is HomeLoaded) {
            // Giới hạn số lượng sản phẩm hiển thị trên trang chủ
            final limitedSaleProducts = state.saleProducts.take(6).toList();
            final limitedNewProducts = state.newProducts.take(6).toList();

            return ListView(
              // Sử dụng ListView để cuộn toàn bộ nội dung
              children: [
                if (state.banners.isNotEmpty) _buildBannerSlider(state.banners),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Sale',
                  products: limitedSaleProducts,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  title: 'Sản phẩm mới',
                  products: limitedNewProducts,
                ),
                const SizedBox(height: 20), // Thêm khoảng trống cuối trang
              ],
            );
          }
          return const Center(
              child: Text('Trạng thái không xác định')); // Trường hợp khác
        },
      ),
    );
  }

  // Widget xây dựng Banner Slider
  Widget _buildBannerSlider(List<BannerModel> banners) {
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _bannerController,
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            return Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 5.0), // Khoảng cách giữa các banner
              child: ClipRRect(
                // Bo góc banner
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  AppConstants.baseUrl + banner.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            );
          },
          options: CarouselOptions(
              autoPlay: true, // Tự động chạy
              aspectRatio: 16 / 9, // Tỉ lệ khung hình (điều chỉnh nếu cần)
              enlargeCenterPage: true, // Banner ở giữa lớn hơn chút
              viewportFraction:
                  0.9, // Phần trăm chiều rộng màn hình mà một banner chiếm
              autoPlayInterval:
                  const Duration(seconds: 5), // Thời gian chuyển banner
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              }
              // Không có nút prev/next mặc định, cần tự tạo nếu muốn
              ),
        ),
        // Optional: Thêm nút điều khiển hoặc dấu chấm chỉ thị
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _bannerController.animateToPage(entry.key),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        .withOpacity(
                            _currentBannerIndex == entry.key ? 0.9 : 0.4)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Widget xây dựng một section sản phẩm (Sale, Mới)
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<ProductModel> products,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Không có sản phẩm nào.',
                style: TextStyle(color: Colors.grey)),
          )
        else
          GridView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0), // Padding cho GridView
            shrinkWrap: true, // Co lại theo nội dung
            physics:
                const NeverScrollableScrollPhysics(), // Không cho GridView cuộn riêng lẻ
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 sản phẩm trên một dòng
              childAspectRatio:
                  1.1, // Tỉ lệ width/height của card (điều chỉnh cho phù hợp)
              crossAxisSpacing: 10, // Khoảng cách ngang giữa các card
              mainAxisSpacing: 10, // Khoảng cách dọc giữa các card
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  print(
                      'Navigate to Product Detail: ${product.name}'); // Placeholder
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(productId: product.id)));
                },
              );
            },
          ),
      ],
    );
  }
}
