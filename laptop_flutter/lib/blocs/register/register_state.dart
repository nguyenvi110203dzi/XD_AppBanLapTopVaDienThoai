part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();
  @override
  List<Object> get props => [];
}

// Trạng thái ban đầu
class RegisterInitial extends RegisterState {}

// Trạng thái đang xử lý đăng ký
class RegisterLoading extends RegisterState {}

// Trạng thái đăng ký thành công
class RegisterSuccess extends RegisterState {
  // Có thể giữ User ở đây nếu cần làm gì đó ngay lập tức,
  // nhưng thường sẽ dựa vào AuthBloc để cập nhật trạng thái đăng nhập chung
  final UserModel user;
  const RegisterSuccess(this.user);
  @override
  List<Object> get props => [user];
}

// Trạng thái đăng ký thất bại
class RegisterFailure extends RegisterState {
  final String error;
  const RegisterFailure(this.error);
  @override
  List<Object> get props => [error];
}
