part of 'profile_edit_bloc.dart';

abstract class ProfileEditState extends Equatable {
  const ProfileEditState();
  @override
  List<Object> get props => [];
}

// Trạng thái ban đầu (hoặc khi chưa có thay đổi)
class ProfileEditInitial extends ProfileEditState {}

// Trạng thái đang lưu
class ProfileEditInProgress extends ProfileEditState {}

// Trạng thái lưu thành công
class ProfileEditSuccess extends ProfileEditState {
  // Không cần giữ user ở đây vì AuthBloc sẽ cập nhật
}

// Trạng thái lưu thất bại
class ProfileEditFailure extends ProfileEditState {
  final String error;
  const ProfileEditFailure(this.error);
  @override
  List<Object> get props => [error];
}
