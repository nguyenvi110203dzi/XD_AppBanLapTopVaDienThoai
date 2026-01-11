part of 'profile_edit_bloc.dart';

abstract class ProfileEditEvent extends Equatable {
  const ProfileEditEvent();
  @override
  List<Object?> get props => [];
}

// Event khi nhấn nút Lưu thay đổi
class ProfileEditSubmitted extends ProfileEditEvent {
  final String? name;
  final String? phone;
  final String? avatarImagePath; // Đường dẫn file ảnh mới nếu có

  const ProfileEditSubmitted({
    this.name,
    this.phone,
    this.avatarImagePath,
  });

  @override
  List<Object?> get props => [name, phone, avatarImagePath];
}
