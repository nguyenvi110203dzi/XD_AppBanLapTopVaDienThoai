part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object> get props => [];
}

// Trạng thái ban đầu
class LoginInitial extends LoginState {}

// Trạng thái đang xử lý đăng nhập
class LoginLoading extends LoginState {}

// Trạng thái đăng nhập thành công
class LoginSuccess extends LoginState {
  // Tương tự RegisterSuccess, không cần giữ User ở đây
  // vì AuthBloc sẽ quản lý trạng thái đăng nhập chung
}

class LoginSuccessAdmin extends LoginState {
  final UserModel user; // Giữ lại user để có thể dùng nếu cần
  const LoginSuccessAdmin(this.user);
  @override
  List<Object> get props => [user];
}

class LoginSuccessCreditCustomer extends LoginState {
  final UserModel user;
  const LoginSuccessCreditCustomer(this.user);
  @override
  List<Object> get props => [user];
}

// Trạng thái đăng nhập thất bại
class LoginFailure extends LoginState {
  final String error;
  const LoginFailure(this.error);
  @override
  List<Object> get props => [error];
}

class LoginSuccessWarehouseStaff extends LoginState {
  final UserModel user;
  const LoginSuccessWarehouseStaff(this.user);
  @override
  List<Object> get props => [user];
}
