part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

// Trạng thái khởi tạo, chưa xác định
class AuthInitial extends AuthState {}

// Trạng thái đã xác thực (đăng nhập)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;
  const AuthAuthenticated({required this.user, required this.token});
  @override
  List<Object?> get props => [user, token];
}

// Trạng thái chưa xác thực (chưa đăng nhập)
class AuthUnauthenticated extends AuthState {}

// Trạng thái đang xử lý (ví dụ: đang kiểm tra token)
class AuthLoading extends AuthState {}

// Trạng thái lỗi (ví dụ: không lấy được profile)
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}
