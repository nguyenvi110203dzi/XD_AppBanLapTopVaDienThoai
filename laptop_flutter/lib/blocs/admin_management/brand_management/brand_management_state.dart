part of 'brand_management_bloc.dart';

abstract class BrandManagementState extends Equatable {
  const BrandManagementState();

  @override
  List<Object> get props => [];
}

// Trạng thái khởi tạo
class BrandInitial extends BrandManagementState {}

// Trạng thái đang tải danh sách
class BrandLoading extends BrandManagementState {}

// Trạng thái tải danh sách thành công
class BrandLoadSuccess extends BrandManagementState {
  final List<Brand> brands;

  const BrandLoadSuccess(this.brands);

  @override
  List<Object> get props => [brands];
}

// Trạng thái tải danh sách thất bại
class BrandLoadFailure extends BrandManagementState {
  final String error;

  const BrandLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Trạng thái đang thực hiện thao tác (Thêm/Sửa/Xóa)
class BrandOperationInProgress extends BrandManagementState {}

// Trạng thái thao tác thành công
class BrandOperationSuccess extends BrandManagementState {
  final String message;
  const BrandOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// Trạng thái thao tác thất bại
class BrandOperationFailure extends BrandManagementState {
  final String error;

  const BrandOperationFailure(this.error);

  @override
  List<Object> get props => [error];
}
