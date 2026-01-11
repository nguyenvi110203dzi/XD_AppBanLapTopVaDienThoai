part of 'user_management_bloc.dart'; // Sẽ tạo file bloc sau

// Lớp cơ sở cho tất cả các state
abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

// Trạng thái ban đầu
class UserManagementInitial extends UserManagementState {}

// Trạng thái đang tải danh sách user
class UserManagementLoading extends UserManagementState {}

// Trạng thái đã tải xong danh sách user
class UserManagementLoaded extends UserManagementState {
  final List<UserModel> users;

  const UserManagementLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

// Trạng thái khi thao tác (Cập nhật role, Xóa) thành công
class UserManagementOperationSuccess extends UserManagementState {
  final String message;
  const UserManagementOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// Trạng thái khi thao tác (Cập nhật role, Xóa) thất bại
class UserManagementOperationFailure extends UserManagementState {
  final String error;
  const UserManagementOperationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// Trạng thái khi tải danh sách ban đầu thất bại
class UserManagementFailure extends UserManagementState {
  final String error;
  const UserManagementFailure(this.error);
  @override
  List<Object?> get props => [error];
}
