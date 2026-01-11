part of 'brand_management_bloc.dart';

abstract class BrandManagementEvent extends Equatable {
  const BrandManagementEvent();

  @override
  List<Object?> get props => [];
}

// Event để tải danh sách thương hiệu
class LoadBrands extends BrandManagementEvent {}

// Event để thêm thương hiệu mới
class AddBrand extends BrandManagementEvent {
  final String name;
  final File? imageFile;

  const AddBrand({required this.name, this.imageFile});

  @override
  List<Object?> get props => [name, imageFile];
}

// Event để cập nhật thương hiệu
class UpdateBrand extends BrandManagementEvent {
  final int id;
  final String name;
  final File? imageFile;

  const UpdateBrand({required this.id, required this.name, this.imageFile});

  @override
  List<Object?> get props => [id, name, imageFile];
}

// Event để xóa thương hiệu
class DeleteBrand extends BrandManagementEvent {
  final int id;

  const DeleteBrand({required this.id});

  @override
  List<Object> get props => [id];
}
