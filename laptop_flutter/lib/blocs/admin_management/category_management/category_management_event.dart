part of 'category_management_bloc.dart';

abstract class CategoryManagementEvent extends Equatable {
  const CategoryManagementEvent();

  @override
  List<Object?> get props => [];
}

// Event để tải danh sách danh mục
class LoadCategories extends CategoryManagementEvent {}

// Event để thêm danh mục mới
class AddCategory extends CategoryManagementEvent {
  final String name;
  final File? imageFile;

  const AddCategory({required this.name, this.imageFile});

  @override
  List<Object?> get props => [name, imageFile];
}

// Event để cập nhật danh mục
class UpdateCategory extends CategoryManagementEvent {
  final int id;
  final String name;
  final File? imageFile;

  const UpdateCategory({required this.id, required this.name, this.imageFile});

  @override
  List<Object?> get props => [id, name, imageFile];
}

// Event để xóa danh mục
class DeleteCategory extends CategoryManagementEvent {
  final int id;

  const DeleteCategory({required this.id});

  @override
  List<Object> get props => [id];
}
