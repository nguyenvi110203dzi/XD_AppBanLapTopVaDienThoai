import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/blocs/admin_management/warehouse_management/warehouse_management_bloc.dart';
import 'package:laptop_flutter/blocs/auth/auth_bloc.dart';
import 'package:laptop_flutter/repositories/warehouse_repository.dart';
import 'package:laptop_flutter/screens/client/main_screens.dart';
import 'package:laptop_flutter/screens/warehouse_staff/warehouse_export_screen.dart';
import 'package:laptop_flutter/screens/warehouse_staff/warehouse_import_screen.dart';
// Import màn hình xem lịch sử nếu có
// import 'package:laptop_flutter/screens/admin/warehouse/product_stock_history_screen.dart'; // Có thể tái sử dụng hoặc tạo mới

class WarehouseStaffMainScreen extends StatefulWidget {
  const WarehouseStaffMainScreen({super.key});

  @override
  State<WarehouseStaffMainScreen> createState() =>
      _WarehouseStaffMainScreenState();
}

class _WarehouseStaffMainScreenState extends State<WarehouseStaffMainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const WarehouseImportScreen(), // Màn hình nhập kho
      const WarehouseExportScreen(), // Màn hình xuất kho
      // Nếu có màn hình xem lịch sử cho NV Kho:
      // ProductStockHistoryScreenWidget(), // Cần tạo widget này hoặc màn hình mới
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String staffName = "Nhân viên Kho";
    if (authState is AuthAuthenticated) {
      staffName = authState.user.name;
    }

    return BlocProvider(
      create: (context) => WarehouseManagementBloc(
        warehouseRepository:
            RepositoryProvider.of<WarehouseRepository>(context),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _selectedIndex == 0 ? 'Nhập Kho Sản Phẩm' : 'Xuất Kho Sản Phẩm'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                  child:
                      Text('Chào, $staffName', style: TextStyle(fontSize: 14))),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () {
                context.read<AuthBloc>().add(AuthLoggedOut());
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) =>
                            const MainLayout()), // Quay về màn hình chính user/login
                    (route) => false);
              },
            )
          ],
        ),
        body: IndexedStack(
          // Dùng IndexedStack để giữ state các tab
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.input),
              label: 'Nhập Kho',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.output),
              label: 'Xuất Kho',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.history),
            //   label: 'Lịch Sử Kho',
            // ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
