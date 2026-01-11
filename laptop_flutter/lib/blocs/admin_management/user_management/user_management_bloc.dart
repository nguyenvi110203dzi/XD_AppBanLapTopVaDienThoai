import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:laptop_flutter/models/user.dart'; // << Import UserModel
import 'package:laptop_flutter/repositories/user_repository.dart'; // << Import UserRepository

part 'user_management_event.dart';
part 'user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final UserRepository _userRepository;

  UserManagementBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(UserManagementInitial()) {
    // Đăng ký các trình xử lý sự kiện
    on<LoadUsers>(_onLoadUsers);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<DeleteUser>(_onDeleteUser);
  }

  // Xử lý LoadUsers
  Future<void> _onLoadUsers(
      LoadUsers event, Emitter<UserManagementState> emit) async {
    print("[UserBloc] Loading Users...");
    emit(UserManagementLoading());
    try {
      final users = await _userRepository.getUsers();
      emit(UserManagementLoaded(users));
      print("[UserBloc] Users Loaded: ${users.length}");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[UserBloc] Load Users Failed: $error");
      emit(UserManagementFailure(error));
    }
  }

  // Xử lý UpdateUserRole
  Future<void> _onUpdateUserRole(
      UpdateUserRole event, Emitter<UserManagementState> emit) async {
    print(
        "[UserBloc] Updating Role for User ID: ${event.userId} to Role: ${event.newRole}");
    // Giữ state hiện tại (thường là Loaded) để UI không bị giật về Loading
    final currentState = state;
    try {
      // Gọi repository để cập nhật chỉ role
      await _userRepository.updateUser(
        event.userId,
        role: event.newRole,
        // Không cần gửi các trường khác nếu chỉ cập nhật role
      );
      emit(UserManagementOperationSuccess('Cập nhật quyền thành công!'));
      add(LoadUsers()); // Tải lại danh sách để cập nhật UI
      print("[UserBloc] Update Role Success, reloading list.");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[UserBloc] Update Role Failed: $error");
      emit(UserManagementOperationFailure(error));
      // Nếu trước đó là Loaded, emit lại để danh sách không biến mất khi lỗi
      if (currentState is UserManagementLoaded) {
        emit(currentState);
      }
    }
  }

  // Xử lý DeleteUser
  Future<void> _onDeleteUser(
      DeleteUser event, Emitter<UserManagementState> emit) async {
    print("[UserBloc] Deleting User ID: ${event.userId}");
    final currentState = state;
    try {
      await _userRepository.deleteUser(event.userId);
      emit(UserManagementOperationSuccess('Xóa người dùng thành công!'));
      add(LoadUsers()); // Tải lại danh sách
      print("[UserBloc] Delete User Success, reloading list.");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[UserBloc] Delete User Failed: $error");
      emit(UserManagementOperationFailure(error));
      if (currentState is UserManagementLoaded) {
        emit(currentState);
      }
    }
  }
}
