import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/screens/client/account/account_screen.dart'; // Dùng lại màn hình tài khoản

import '../../../blocs/credit_order_history/credit_order_history_bloc.dart';
import '../../../repositories/credit_order_repository.dart';
import 'credit_order_history_screen.dart';
// Import các màn hình mới sẽ tạo
import 'credit_product_list_screen.dart';

class CreditCustomerMainScreen extends StatefulWidget {
  const CreditCustomerMainScreen({super.key});

  @override
  State<CreditCustomerMainScreen> createState() =>
      _CreditCustomerMainScreenState();
}

class _CreditCustomerMainScreenState extends State<CreditCustomerMainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const CreditProductListScreen(),
      BlocProvider<CreditOrderHistoryBloc>(
        // Đảm bảo bạn tạo BlocProvider ở đây
        create: (context) => CreditOrderHistoryBloc(
          creditOrderRepository: context.read<CreditOrderRepository>(),
        )..add(const LoadMyCreditOrders(statusFilter: null)),
        child: const CreditOrderHistoryScreen(),
      ),
      const AccountScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Mua Hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Công Nợ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrangeAccent, // Màu khác biệt
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
