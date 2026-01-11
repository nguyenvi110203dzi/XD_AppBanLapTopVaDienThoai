import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../repositories/auth_repository.dart';
import '../auth/auth_bloc.dart'; // Import AuthBloc để cập nhật

part 'profile_edit_event.dart';
part 'profile_edit_state.dart';

class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc; // Cần để cập nhật user sau khi thành công

  ProfileEditBloc({required this.authRepository, required this.authBloc})
      : super(ProfileEditInitial()) {
    on<ProfileEditSubmitted>(_onProfileEditSubmitted);
  }

  Future<void> _onProfileEditSubmitted(
      ProfileEditSubmitted event, Emitter<ProfileEditState> emit) async {
    emit(ProfileEditInProgress());
    try {
      // Gọi repository để cập nhật
      final updatedUser = await authRepository.updateUserProfile(
        name: event.name,
        phone: event.phone,
        avatarImagePath: event.avatarImagePath,
      );

      // Cập nhật lại AuthBloc với thông tin User mới
      authBloc.add(AuthLoggedIn(user: updatedUser));

      emit(ProfileEditSuccess()); // Báo thành công
    } catch (e) {
      print("Profile Edit Error: $e");
      emit(ProfileEditFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
