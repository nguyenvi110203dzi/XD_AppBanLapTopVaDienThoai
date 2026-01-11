import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../auth/auth_bloc.dart'; // Import AuthBloc

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc; // Tham chiếu đến AuthBloc chung

  LoginBloc({required this.authRepository, required this.authBloc})
      : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      // Gọi API đăng nhập từ repository
      final response = await authRepository.login(event.email, event.password);
      final user = UserModel.fromJson(response['user']);
      // <<< BẮT ĐẦU THAY ĐỔI >>>
      if (user.role == 1) {
        // Admin
        authBloc.add(AuthLoggedIn(user: user));
        emit(LoginSuccessAdmin(user));
      } else if (user.role == 2) {
        // Khách hàng công nợ
        authBloc.add(AuthLoggedIn(user: user));
        emit(LoginSuccessCreditCustomer(user));
      } else if (user.role == 3) {
        // Nhân viên kho
        authBloc.add(AuthLoggedIn(user: user));
        emit(LoginSuccessWarehouseStaff(user)); // Emit state mới
      }
      // <<< KẾT THÚC THAY ĐỔI >>>
      else {
        // User thường
        authBloc.add(AuthLoggedIn(user: user));
        emit(LoginSuccess());
      }
      // Báo đăng nhập thành công
    } catch (e) {
      print("Login Error: $e");
      emit(LoginFailure(
          e.toString().replaceFirst('Exception: ', ''))); // Báo lỗi
    }
  }
}
