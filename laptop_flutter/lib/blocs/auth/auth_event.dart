part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

// Event khi ứng dụng khởi động để kiểm tra trạng thái đăng nhập
class AuthAppStarted extends AuthEvent {}

// Event khi người dùng đăng nhập thành công
class AuthLoggedIn extends AuthEvent {
  final UserModel user; // Truyền thông tin user đã đăng nhập
  // Token đã được lưu trong repository nên không cần truyền ở đây nữa
  const AuthLoggedIn({required this.user});
  @override
  List<Object?> get props => [user];
}

// Event khi người dùng đăng xuất
class AuthLoggedOut extends AuthEvent {}
