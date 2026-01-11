import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/screens/admin/baohanh/admin_bao_hanh_screen.dart'; // Đảm bảo đường dẫn chính xác
import 'package:laptop_flutter/screens/admin/thongso/admin_camera_list_screen.dart';
import 'package:laptop_flutter/screens/admin/thongso/admin_cauhinh_list_screen.dart';
import 'package:laptop_flutter/screens/admin/thongso/admin_pinsac_list_screen.dart';
import 'package:laptop_flutter/screens/admin/warehouse/admin_warehouse_management_screen.dart';
import 'package:laptop_flutter/screens/client/main_screens.dart';

import '../../blocs/admin_management/chat_management/admin_chat_bloc.dart';
import '../../blocs/admin_management/credit_order_management/admin_credit_order_bloc.dart';
import '../../blocs/admin_management/order_management/admin_order_bloc.dart';
import '../../blocs/admin_management/thongso_management/camera/camera_bloc.dart';
import '../../blocs/admin_management/thongso_management/cauhinh/cauhinh_bloc.dart';
import '../../blocs/admin_management/thongso_management/pinsac/pinsac_bloc.dart';
import '../../blocs/admin_management/warehouse_management/warehouse_management_bloc.dart';
import '../../blocs/auth/auth_bloc.dart'; // Để lấy user và logout
import '../../config/app_constants.dart';
import '../../repositories/credit_order_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/spec_repository.dart';
import '../../repositories/warehouse_repository.dart';
import 'account/admin_user_management_screen.dart';
import 'banner/admin_banner_management_screen.dart';
import 'brand/admin_brand_management_screen.dart';
import 'category/admin_category_management_screen.dart';
// Import các màn hình admin placeholder
import 'chat_management/admin_chat_dashboard_screen.dart';
import 'credit_order/admin_credit_order_management_screen.dart';
import 'home/admin_home_screen.dart';
import 'order/admin_order_management_screen.dart';
import 'product/admin_product_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0; // Index của màn hình admin đang được chọn
  String _appBarTitle = 'Admin Home'; // Title AppBar mặc định

  // Danh sách các màn hình admin tương ứng với menu
  final List<Widget> _adminScreens = [
    const AdminHomeScreen(),
    const AdminUserManagementScreen(),
    const AdminBannerManagementScreen(),
    const AdminBrandManagementScreen(),
    const AdminCategoryManagementScreen(),
    const AdminProductManagementScreen(),
    BlocProvider<AdminOrderBloc>(
      create: (context) => AdminOrderBloc(
        // Lấy OrderRepository đã được cung cấp ở main.dart hoặc widget cha
        orderRepository: RepositoryProvider.of<OrderRepository>(context),
      )..add(LoadAllAdminOrders()), // Gọi event load dữ liệu ngay khi tạo Bloc
      child: const AdminOrderManagementScreen(),
    ),
    BlocProvider<CauHinhBloc>(
      // 7 << INDEX MỚI
      create: (context) => CauHinhBloc(
        // Lấy Repositories đã được cung cấp ở main.dart hoặc widget cha
        specRepository: RepositoryProvider.of<SpecRepository>(context),
        productRepository: RepositoryProvider.of<ProductRepository>(context),
      )..add(LoadAllCauHinh()), // Load dữ liệu ban đầu
      child: const AdminCauHinhListScreen(), // Màn hình quản lý cấu hình
    ),
    // TODO: Thêm các màn hình quản lý Camera, PinSac tương tự nếu cần
    // Ví dụ:
    BlocProvider<CameraBloc>(
      // 8
      create: (context) => CameraBloc(
        // Lấy repo từ context cha (đã được provide ở main.dart)
        specRepository:
            RepositoryProvider.of<SpecRepository>(context), // << ĐÃ THÊM
        productRepository:
            RepositoryProvider.of<ProductRepository>(context), // << ĐÃ THÊM
      )..add(LoadAllCamera()),
      child: const AdminCameraListScreen(),
    ),
    BlocProvider<PinSacBloc>(
      // 9
      create: (context) => PinSacBloc(
        specRepository:
            RepositoryProvider.of<SpecRepository>(context), // << ĐÃ THÊM
        productRepository: RepositoryProvider.of<ProductRepository>(context),
      )..add(LoadAllPinSac()),
      child: const AdminPinSacListScreen(),
    ),
    BlocProvider<AdminChatBloc>(
      // 10 << INDEX 10
      create: (context) => AdminChatBloc(
        authBloc: BlocProvider.of<AuthBloc>(context), // Truyền AuthBloc
      ),
      child: const AdminChatDashboardScreen(),
    ),
    const AdminBaoHanhScreen(),
    BlocProvider<AdminCreditOrderBloc>(
      // Sẽ tạo BLoC này
      create: (context) => AdminCreditOrderBloc(
        creditOrderRepository:
            RepositoryProvider.of<CreditOrderRepository>(context),
      )..add(const LoadAllAdminCreditOrders(
          forceRefresh: true)), // Load tất cả đơn ban đầu
      child: const AdminCreditOrderManagementScreen(), // Sẽ tạo màn hình này
    ),
    BlocProvider<WarehouseManagementBloc>(
      // Index 13
      create: (context) => WarehouseManagementBloc(
        warehouseRepository:
            RepositoryProvider.of<WarehouseRepository>(context),
      )..add(LoadOverallQuantityEvent()), // Load tổng kho cho Admin
      child: const AdminWarehouseManagementScreen(),
    ),
  ];

  // Danh sách các tiêu đề tương ứng
  final List<String> _adminScreenTitles = [
    'Thống kê', // Home
    'Quản lý Tài khoản',
    'Quản lý Banner',
    'Quản lý Thương hiệu',
    'Quản lý Danh mục',
    'Quản lý Sản phẩm',
    'Quản lý Đơn hàng',
    'QL Cấu hình Bộ nhớ',
    'QL Camera & Màn hình',
    'QL Pin & Sạc',
    'Quản lý Tư vấn',
    'Quản lý Bảo hành',
    'QL Đơn Công Nợ',
    'Quản lý Kho Hàng',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarTitle = _adminScreenTitles[index]; // Cập nhật title AppBar
    });
    Navigator.pop(context); // Đóng Drawer sau khi chọn
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user từ AuthBloc để hiển thị trong Drawer Header (ví dụ)
    final userState = context.watch<AuthBloc>().state;
    String userName = 'Admin';
    String userEmail = '';
    String? userAvatar;
    if (userState is AuthAuthenticated) {
      userName = userState.user.name;
      userEmail = userState.user.email;
      userAvatar = userState.user.avatar;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle), // Title thay đổi theo mục được chọn
        // actions: [ IconButton(icon: Icon(Icons.search), onPressed: () {})], // Có thể thêm action nếu cần
      ),
      // --- DRAWER (MENU HAMBURGER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header của Drawer
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (userAvatar != null &&
                        userAvatar.isNotEmpty &&
                        Uri.tryParse(userAvatar)?.hasAbsolutePath == true)
                    ? NetworkImage(AppConstants.baseUrl + userAvatar)
                    : null,
                child: (userAvatar == null ||
                        userAvatar.isEmpty ||
                        Uri.tryParse(userAvatar ?? '')?.hasAbsolutePath != true)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            // Các mục menu
            _buildDrawerItem(Icons.home_outlined, 'Thống kê', 0, _onSelectItem),
            _buildDrawerItem(Icons.people_alt_outlined, 'Quản lý Tài khoản', 1,
                _onSelectItem),
            _buildDrawerItem(
                Icons.image_outlined, 'Quản lý Banner', 2, _onSelectItem),
            _buildDrawerItem(Icons.storefront_outlined, 'Quản lý Thương hiệu',
                3, _onSelectItem),
            _buildDrawerItem(
                Icons.category_outlined, 'Quản lý Danh mục', 4, _onSelectItem),
            _buildDrawerItem(Icons.inventory_2_outlined, 'Quản lý Sản phẩm', 5,
                _onSelectItem),
            _buildDrawerItem(Icons.receipt_long_outlined, 'Quản lý Đơn hàng', 6,
                _onSelectItem),
            _buildDrawerItem(Icons.support_agent_outlined, 'Quản lý Tư vấn', 10,
                _onSelectItem),
            _buildDrawerItem(Icons.shield_outlined, 'Quản lý Bảo hành', 11,
                _onSelectItem), // Icon ví dụ
            _buildDrawerItem(Icons.request_quote_outlined, 'QL Đơn Công Nợ', 12,
                _onSelectItem),
            _buildDrawerItem(Icons.inventory_2_outlined, 'Quản lý Kho Hàng', 13,
                _onSelectItem), // Giả sử index là 13
            const Divider(), // Thêm đường kẻ phân cách
            const Padding(
              // Thêm tiêu đề nhỏ cho nhóm quản lý thông số
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Quản lý Thông số SP',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey)),
            ),
            _buildDrawerItem(Icons.memory, 'Cấu hình Bộ nhớ', 7, _onSelectItem),
            // TODO: Thêm các mục cho Camera, PinSac khi có màn hình tương ứng
            _buildDrawerItem(Icons.camera_alt_outlined, 'Camera & Màn hình', 8,
                _onSelectItem),
            _buildDrawerItem(
                Icons.battery_charging_full, 'Pin & Sạc', 9, _onSelectItem),
            const Divider(),
            // Nút Đăng xuất
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer trước
                // Gửi event logout đến AuthBloc
                context.read<AuthBloc>().add(AuthLoggedOut());
                // Điều hướng về màn hình chính của user và xóa stack admin
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MainLayout()), // Quay về màn hình chính user
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      // --- BODY (Hiển thị màn hình admin được chọn) ---
      body: IndexedStack(
        // Dùng IndexedStack để giữ state các màn hình admin
        index: _selectedIndex,
        children: _adminScreens,
      ),
    );
  }

  // Helper tạo một mục trong Drawer
  Widget _buildDrawerItem(
      IconData icon, String title, int index, Function(int) onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index, // Đánh dấu mục đang được chọn
      selectedTileColor:
          Theme.of(context).primaryColor.withOpacity(0.1), // Màu khi được chọn
      onTap: () => onTap(index),
    );
  }
}
