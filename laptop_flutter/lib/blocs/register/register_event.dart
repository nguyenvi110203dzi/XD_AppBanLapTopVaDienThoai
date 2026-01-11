part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();
  @override
  List<Object?> get props => [];
}

// Event khi người dùng nhấn nút Đăng ký
class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String email;
  final String password;
  final String? phone; // Thêm phone nếu bạn có trường nhập liệu cho nó

  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [name, email, password, phone];
}
