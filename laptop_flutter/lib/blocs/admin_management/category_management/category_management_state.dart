part of 'category_management_bloc.dart';

abstract class CategoryManagementState extends Equatable {
  const CategoryManagementState();

  @override
  List<Object> get props => [];
}

// Trạng thái khởi tạo
class CategoryInitial extends CategoryManagementState {}

// Trạng thái đang tải danh sách
class CategoryLoading extends CategoryManagementState {}

// Trạng thái tải danh sách thành công
class CategoryLoadSuccess extends CategoryManagementState {
  final List<Category> categories;

  const CategoryLoadSuccess(this.categories);

  @override
  List<Object> get props => [categories];
}

// Trạng thái tải danh sách thất bại
class CategoryLoadFailure extends CategoryManagementState {
  final String error;

  const CategoryLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Trạng thái đang thực hiện thao tác (Thêm/Sửa/Xóa)
class CategoryOperationInProgress extends CategoryManagementState {}

// Trạng thái thao tác thành công
class CategoryOperationSuccess extends CategoryManagementState {
  final String message;
  const CategoryOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// Trạng thái thao tác thất bại
class CategoryOperationFailure extends CategoryManagementState {
  final String error;

  const CategoryOperationFailure(this.error);

  @override
  List<Object> get props => [error];
}
