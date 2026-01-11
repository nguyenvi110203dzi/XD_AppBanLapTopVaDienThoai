part of 'user_management_bloc.dart'; // Sẽ tạo file bloc sau

// Lớp cơ sở cho tất cả các event
abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

// Event để yêu cầu tải danh sách người dùng
class LoadUsers extends UserManagementEvent {}

// Event để yêu cầu cập nhật quyền (role) của người dùng
class UpdateUserRole extends UserManagementEvent {
  final int userId;
  final int newRole; // 0 = User, 1 = Admin (Hoặc theo định nghĩa của bạn)

  const UpdateUserRole({required this.userId, required this.newRole});

  @override
  List<Object?> get props => [userId, newRole];
}

// Event để yêu cầu xóa người dùng
class DeleteUser extends UserManagementEvent {
  final int userId;

  const DeleteUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Có thể thêm các event khác sau này nếu cần admin sửa tên, phone, avatar user
// class UpdateUserDetails extends UserManagementEvent { ... }
