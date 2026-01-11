import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/models/user.dart';

import '../../../blocs/admin_management/user_management/user_management_bloc.dart';
import '../../../repositories/auth_repository.dart'; // UserRepository cần AuthRepository
import '../../../repositories/user_repository.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  // Hàm helper để lấy text hiển thị cho role
  String _getRoleText(int? role) {
    switch (role) {
      case 0:
        return 'User';
      case 1:
        return 'Admin'; // Mặc dù ta đã lọc admin ra, nhưng để đây cho đủ
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp UserManagementBloc cho màn hình này
    return BlocProvider(
      create: (context) => UserManagementBloc(
        // Lấy UserRepository đã được cung cấp ở trên (main.dart)
        userRepository: RepositoryProvider.of<UserRepository>(context),
      )..add(LoadUsers()), // Load danh sách user ngay khi tạo Bloc
      child: Scaffold(
        body: BlocListener<UserManagementBloc, UserManagementState>(
          listener: (context, state) {
            // Hiển thị SnackBar cho các thao tác thành công/thất bại
            if (state is UserManagementOperationSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green));
            } else if (state is UserManagementOperationFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Lỗi thao tác: ${state.error}"),
                    backgroundColor: Colors.red));
            }
          },
          child: BlocBuilder<UserManagementBloc, UserManagementState>(
            builder: (context, state) {
              // 1. Trạng thái Loading
              if (state is UserManagementLoading &&
                  state is! UserManagementOperationFailure &&
                  state is! UserManagementOperationSuccess) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Trạng thái Lỗi tải ban đầu
              if (state is UserManagementFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Lỗi tải danh sách người dùng: ${state.error}'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => context
                              .read<UserManagementBloc>()
                              .add(LoadUsers()),
                          child: const Text('Thử lại'),
                        )
                      ],
                    ),
                  ),
                );
              }

              // 3. Trạng thái đã tải (Loaded) hoặc sau khi thao tác (Operation)
              List<UserModel> users = [];
              if (state is UserManagementLoaded) {
                users = state.users;
              } else if (state is UserManagementOperationSuccess ||
                  state is UserManagementOperationFailure) {
                // Lấy danh sách từ state trước đó nếu có thể (cần Bloc lưu state hoặc cách khác)
                // Cách đơn giản nhất là chờ LoadUsers chạy lại sau khi operation thành công/thất bại
                // Để tránh màn hình trống, tạm thời có thể tìm state Loaded gần nhất
                final currentState = context.read<UserManagementBloc>().state;
                if (currentState is UserManagementLoaded) {
                  users = currentState.users;
                } else {
                  // Nếu không tìm thấy state loaded cũ, hiện loading
                  return const Center(child: CircularProgressIndicator());
                }
              }

              // Hiển thị thông báo nếu danh sách rỗng
              if (users.isEmpty && state is UserManagementLoaded) {
                return const Center(
                    child: Text('Không có người dùng nào (ngoài Admin).'));
              } else if (users.isEmpty && state is! UserManagementLoaded) {
                // Vẫn đang loading sau operation lỗi?
                return const Center(child: CircularProgressIndicator());
              }

              // --- Hiển thị ListView danh sách User ---
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<UserManagementBloc>().add(LoadUsers());
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    String url = context.read<AuthRepository>().baseUrl;
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade300,
                          // Hiển thị avatar
                          backgroundImage: user.avatar != null
                              ? NetworkImage(url + user.avatar!)
                              : null, // Nếu không, không đặt backgroundImage
                          child: (user.avatar == null || user.avatar!.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(user.name ?? 'N/A',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email ?? 'N/A'),
                            Text('Quyền: ${_getRoleText(user.role)}',
                                style: TextStyle(
                                    color: user.role == 1
                                        ? Colors.red
                                        : Colors.green,
                                    fontStyle: FontStyle.italic)),
                            if (user.phone != null && user.phone!.isNotEmpty)
                              Text('SĐT: ${user.phone}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút thay đổi quyền (ví dụ: chuyển user thành admin và ngược lại)
                            // Cẩn thận khi cho phép chuyển thành Admin
                            if (user.role ==
                                0) // Chỉ hiển thị nút nâng quyền cho User thường
                              IconButton(
                                icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.orange),
                                tooltip: 'Đặt làm Admin',
                                onPressed: () {
                                  // Xác nhận trước khi thay đổi quyền
                                  _showChangeRoleConfirmationDialog(
                                      context, user, 1); // Đặt role = 1 (Admin)
                                },
                              ),
                            // Nút xóa người dùng
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Xóa Người dùng',
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, user);
                              },
                            ),
                          ],
                        ),
                        isThreeLine:
                            true, // Cho phép subtitle hiển thị nhiều dòng hơn
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Dialog Xác nhận Thay đổi Quyền ---
  void _showChangeRoleConfirmationDialog(
      BuildContext context, UserModel user, int newRole) {
    final bloc =
        BlocProvider.of<UserManagementBloc>(context); // Lấy Bloc từ context
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              Text(newRole == 1 ? 'Xác nhận Nâng quyền' : 'Xác nhận Hạ quyền'),
          content: Text(
              'Bạn có chắc chắn muốn đặt quyền của "${user.name}" thành ${_getRoleText(newRole)} không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: newRole == 1 ? Colors.orange : Colors.blue),
              onPressed: () {
                bloc.add(UpdateUserRole(userId: user.id, newRole: newRole));
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
              child: Text(newRole == 1 ? 'Đặt làm Admin' : 'Đặt làm User',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- Dialog Xác nhận Xóa Người dùng ---
  void _showDeleteConfirmationDialog(BuildContext context, UserModel user) {
    final bloc =
        BlocProvider.of<UserManagementBloc>(context); // Lấy Bloc từ context
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa người dùng "${user.name}" (${user.email}) không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                bloc.add(DeleteUser(userId: user.id));
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
