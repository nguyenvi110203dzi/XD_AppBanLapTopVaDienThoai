import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLoggedOut>(_onLoggedOut);

    // Tự động kiểm tra khi Bloc được tạo
    // add(AuthAppStarted()); // Chuyển việc gọi này ra main.dart để đảm bảo repo đã sẵn sàng
  }
  Future<void> _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) async {
    // Giả sử event.user là UserModel và event.token là chuỗi token
    // Hoặc bạn có thể lấy token từ authRepository sau khi login thành công
    final token = await authRepository.getToken(); // Hoặc lấy từ response login
    if (token != null) {
      emit(AuthAuthenticated(
          user: event.user, token: token)); // <-- TRUYỀN TOKEN
    } else {
      // Xử lý trường hợp không có token (dù login thành công thì nên có)
      emit(AuthFailure("Lỗi: Không tìm thấy token sau khi đăng nhập."));
    }
  }

  Future<void> _onAppStarted(
      AuthAppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final bool hasToken = await authRepository.hasToken();

    if (hasToken) {
      try {
        final user = await authRepository.getUserProfile();
        final token = await authRepository.getToken(); // Lấy lại token đã lưu
        if (token != null) {
          emit(AuthAuthenticated(user: user, token: token)); // <-- TRUYỀN TOKEN
        } else {
          // Token đã bị xóa hoặc không hợp lệ
          await authRepository.deleteToken();
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        await authRepository.deleteToken();
        emit(AuthUnauthenticated());
        print("AuthAppStarted Error: $e");
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoggedOut(
      AuthLoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // Có thể hiển thị loading ngắn khi logout
    await authRepository.logout(); // Gọi repo để xóa token
    emit(AuthUnauthenticated()); // Chuyển về trạng thái chưa đăng nhập
  }
}
