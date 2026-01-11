part of 'product_management_bloc.dart'; // Sẽ tạo file bloc sau

// Lớp cơ sở
abstract class ProductManagementState extends Equatable {
  const ProductManagementState();
  @override
  List<Object?> get props => [];
}

// Trạng thái ban đầu
class ProductManagementInitial extends ProductManagementState {}

// Trạng thái đang tải danh sách
class ProductManagementLoading extends ProductManagementState {}

// Trạng thái đã tải xong danh sách sản phẩm
// Bao gồm cả Brand và Category để hiển thị tên trong danh sách
class ProductManagementLoaded extends ProductManagementState {
  final List<ProductModel> products;
  // Có thể thêm list Brand và Category ở đây nếu cần cho Dropdown trong màn hình chính
  final List<Brand> brands;
  final List<Category> categories;

  const ProductManagementLoaded(this.products, this.brands, this.categories);

  @override
  List<Object?> get props => [products]; // , brands, categories];
}

// State cho biết thao tác (Thêm/Sửa/Xóa) thành công
class ProductManagementOperationSuccess extends ProductManagementState {
  final String message;
  const ProductManagementOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// State cho biết thao tác (Thêm/Sửa/Xóa) thất bại
class ProductManagementOperationFailure extends ProductManagementState {
  final String error;
  const ProductManagementOperationFailure(this.error);
  @override
  List<Object?> get props => [error];
}

// State khi tải danh sách ban đầu thất bại
class ProductManagementFailure extends ProductManagementState {
  final String error;
  const ProductManagementFailure(this.error);
  @override
  List<Object?> get props => [error];
}
