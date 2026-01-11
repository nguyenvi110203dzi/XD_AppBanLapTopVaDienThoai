import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../auth/auth_bloc.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc; // Tham chiếu đến AuthBloc chung

  RegisterBloc({required this.authRepository, required this.authBloc})
      : super(RegisterInitial()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event, Emitter<RegisterState> emit) async {
    // TODO: Thêm validation cơ bản ở đây nếu muốn (ngoài Form validation)
    // Ví dụ: kiểm tra mật khẩu đủ mạnh,...

    emit(RegisterLoading()); // Báo đang xử lý
    try {
      // Gọi API đăng ký từ repository
      final response = await authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );

      // API trả về Map chứa 'user' và 'token' khi thành công
      final user = UserModel.fromJson(
          response['user']); // Tạo đối tượng User từ response
      // Token đã được lưu trong repo, giờ báo cho AuthBloc biết đã đăng nhập
      authBloc.add(AuthLoggedIn(user: user));

      emit(RegisterSuccess(user)); // Báo đăng ký thành công
    } catch (e) {
      print("Register Error: $e");
      emit(RegisterFailure(e
          .toString()
          .replaceFirst('Exception: ', ''))); // Báo lỗi, bỏ phần "Exception: "
    }
  }
}
