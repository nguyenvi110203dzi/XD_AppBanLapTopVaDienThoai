import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/chat/user_chat_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../models/user.dart';
import '../../auth/login_screen.dart';
import '../../auth/register_screen.dart';
import '../chat/chat_screen.dart';
import '../order/order_history_screen.dart';
import 'edit_profile_screen.dart'; // Import User model

// Import các màn hình khác (tạo placeholder nếu chưa có)
// import '../order/order_history_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Không cần AppBar riêng nếu MainScreen đã có AppBar chung
      // appBar: AppBar(title: Text('Tài khoản')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Hiển thị loading khi đang kiểm tra trạng thái đăng nhập ban đầu
          if (state is AuthInitial || state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hiển thị nội dung dựa trên trạng thái Authenticated hoặc Unauthenticated
          return ListView(
            // Dùng ListView để nội dung có thể dài và cuộn
            children: [
              // --- Phần Header: Thông tin User hoặc Nút Đăng nhập/Đăng ký ---
              if (state is AuthAuthenticated)
                _buildUserInfoSection(context, state.user) // Truyền user vào
              else // AuthUnauthenticated hoặc AuthFailure
                _buildLoginRegisterSection(context),

              // --- (Optional) Thanh thông báo ---
              // _buildNotificationBar(context),

              // --- Phần Đơn mua ---
              if (state is AuthAuthenticated) // Chỉ hiển thị khi đã đăng nhập
                _buildOrderSection(context),

              // --- (Optional) Các mục cài đặt khác ---
              const Divider(height: 20, thickness: 1),
              ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Cài đặt tài khoản'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {/* TODO: Navigate to settings */},
              ),
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Trợ giúp & Hỗ trợ'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  if (state is AuthAuthenticated) {
                    // Chỉ cho phép khi đã đăng nhập
                    Navigator.push(
                      // << ĐANG DÙNG PUSH
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (context) => UserChatBloc(
                            authBloc: BlocProvider.of<AuthBloc>(context),
                          ),
                          child: const ChatScreen(),
                        ),
                      ),
                    );
                  } else {
                    // Yêu cầu đăng nhập nếu chưa đăng nhập
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Vui lòng đăng nhập để sử dụng chức năng này.')),
                    );
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LoginScreen()));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Về ứng dụng'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {/* TODO: Navigate to about */},
              ),

              // --- Nút Đăng xuất ---
              if (state is AuthAuthenticated)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade100)),
                    onPressed: () {
                      // Xác nhận trước khi đăng xuất
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Đăng xuất?'),
                          content: Text(
                              'Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Hủy')),
                            TextButton(
                              onPressed: () {
                                // Gọi event đăng xuất
                                context.read<AuthBloc>().add(AuthLoggedOut());
                                Navigator.pop(ctx); // Đóng dialog
                                // Có thể thêm thông báo đã đăng xuất thành công
                              },
                              child: Text('Đăng xuất',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Đăng Xuất'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Widget hiển thị khi chưa đăng nhập
  Widget _buildLoginRegisterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      color: Theme.of(context).primaryColor.withOpacity(0.1), // Màu nền nhẹ
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              print('Navigate to Login Screen');
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
            child: const Text('Đăng Nhập'),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () {
              print('Navigate to Register Screen');
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => RegisterScreen()));
            },
            child: const Text('Đăng Ký'),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thông tin user khi đã đăng nhập
  Widget _buildUserInfoSection(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor, // Màu nền giống hình ảnh
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white, // Nền trắng cho avatar
            backgroundImage: user.avatar != null
                ? NetworkImage(AppConstants.baseUrl + user.avatar!)
                : null,
          ),
          const SizedBox(width: 16),
          // Tên và thông tin khác
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name, // Hiển thị tên user
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Có thể thêm các thông tin khác như email, số người theo dõi...
                Text(
                  user.email, // Hiển thị email
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                // Text('1 Người theo dõi - 194 Đang theo dõi', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          // Nút chỉnh sửa profile (ví dụ)
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Widget hiển thị phần đơn mua hàng
  Widget _buildOrderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề và link xem lịch sử
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn mua',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  print('Navigate to Order History (All)');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => OrderHistoryScreen()));
                },
                child: const Text('Xem lịch sử mua hàng >',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Các icon trạng thái đơn hàng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderStatusIcon(
                  context, Icons.receipt_long_outlined, 'Chờ xác nhận', 0),
              _buildOrderStatusIcon(
                  context, Icons.inventory_2_outlined, 'Chờ lấy hàng', 1),
              _buildOrderStatusIcon(
                  context, Icons.local_shipping_outlined, 'Chờ giao hàng', 2),
              _buildOrderStatusIcon(
                  context, Icons.star_border, 'Đã giao', 3), // 4 là đã hủy
            ],
          ),
        ],
      ),
    );
  }

  // Widget cho một icon trạng thái đơn hàng
  Widget _buildOrderStatusIcon(
      BuildContext context, IconData icon, String label, int statusFilter) {
    return InkWell(
      // Dùng InkWell để có hiệu ứng nhấn
      onTap: () {
        print('Navigate to Order History with filter: $statusFilter');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    OrderHistoryScreen(initialStatusFilter: statusFilter)));
      },
      borderRadius: BorderRadius.circular(8), // Bo góc cho hiệu ứng nhấn
      child: Padding(
        // Thêm padding để vùng nhấn rộng hơn
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: Thêm Badge nếu có API đếm số lượng đơn hàng theo trạng thái
            Icon(icon, size: 30, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

// Widget cho thanh thông báo (nếu cần)
// Widget _buildNotificationBar(BuildContext context) { ... }
}
