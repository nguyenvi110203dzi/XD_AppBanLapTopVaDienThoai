import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/cart/cart_bloc.dart';
import 'account/account_screen.dart';
import 'brands/brands_screen.dart';
import 'cart/cart_screen.dart';
import 'categories/categories_screen.dart';
import 'home/home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // Index của tab đang được chọn

  // Danh sách các màn hình tương ứng với các tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    BrandScreen(),
    CartScreen(),
    CategoryScreen(),
    AccountScreen(),
  ];

  // Hàm xử lý khi một tab được chọn
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body sẽ hiển thị màn hình tương ứng với tab được chọn
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Icon khi được chọn
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Brand',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<CartBloc, CartState>(
              // << Bọc icon bằng BlocBuilder
              builder: (context, state) {
                // Dùng Stack để đặt badge lên trên icon
                return Badge(
                  // Widget Badge có sẵn từ Material 3 (SDK 3.0 trở lên)
                  label:
                      Text('${state.itemCount}'), // Hiển thị số loại sản phẩm
                  isLabelVisible:
                      state.itemCount > 0, // Chỉ hiển thị khi có hàng
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            activeIcon: BlocBuilder<CartBloc, CartState>(
              // Tương tự cho activeIcon
              builder: (context, state) {
                return Badge(
                  label: Text('${state.itemCount}'),
                  isLabelVisible: state.itemCount > 0,
                  child: const Icon(Icons.shopping_cart),
                );
              },
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Category',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex, // Tab hiện tại đang được chọn
        selectedItemColor: Colors.amber[800], // Màu của item được chọn
        unselectedItemColor: Colors.grey, // Màu của item không được chọn
        showUnselectedLabels: true, // Hiển thị label của item không được chọn
        onTap: _onItemTapped, // Hàm xử lý khi nhấn vào tab
        type: BottomNavigationBarType.fixed, // Giữ cố định vị trí các item
      ),
    );
  }
}
