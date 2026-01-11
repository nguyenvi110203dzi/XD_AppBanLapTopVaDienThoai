part of 'banner_management_bloc.dart';

abstract class BannerManagementEvent extends Equatable {
  const BannerManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadBanners extends BannerManagementEvent {}

class AddBanner extends BannerManagementEvent {
  final String? name; // Name có thể null
  final int status; // Status là bắt buộc
  final File? imageFile; // Image có thể null khi thêm? (Kiểm tra backend)

  const AddBanner({this.name, required this.status, this.imageFile});

  @override
  List<Object?> get props => [name, status, imageFile];
}

class UpdateBanner extends BannerManagementEvent {
  final int id;
  final String? name; // Name có thể null
  final int status; // Status là bắt buộc
  final File? imageFile; // Image có thể null (giữ ảnh cũ)

  const UpdateBanner(
      {required this.id, this.name, required this.status, this.imageFile});

  @override
  List<Object?> get props => [id, name, status, imageFile];
}

class DeleteBanner extends BannerManagementEvent {
  final int id;

  const DeleteBanner({required this.id});

  @override
  List<Object> get props => [id];
}
