part of 'product_management_bloc.dart'; // Sẽ tạo file bloc sau

// Lớp cơ sở
abstract class ProductManagementEvent extends Equatable {
  const ProductManagementEvent();
  @override
  List<Object?> get props => [];
}

// Event tải danh sách sản phẩm (có thể thêm filter sau này)
class LoadAdminProducts extends ProductManagementEvent {}

// Event thêm sản phẩm mới
class AddProduct extends ProductManagementEvent {
  final String name;
  final int price;
  final int? oldprice;
  final String description;
  final String specification;
  final int quantity;
  final int brandId;
  final int categoryId;
  final XFile? imageFile; // Ảnh có thể null

  const AddProduct({
    required this.name,
    required this.price,
    this.oldprice,
    required this.description,
    required this.specification,
    required this.quantity,
    required this.brandId,
    required this.categoryId,
    this.imageFile,
  });

  @override
  List<Object?> get props => [
        name,
        price,
        oldprice,
        description,
        specification,
        quantity,
        brandId,
        categoryId,
        imageFile
      ];
}

// Event cập nhật sản phẩm
class UpdateProduct extends ProductManagementEvent {
  final int productId;
  final String? name; // Các trường đều optional khi update
  final int? price;
  final int? oldprice;
  final String? description;
  final String? specification;
  final int? quantity;
  final int? brandId;
  final int? categoryId;
  final XFile? imageFile; // Ảnh mới, null nếu không đổi

  const UpdateProduct({
    required this.productId,
    this.name,
    this.price,
    this.oldprice,
    this.description,
    this.specification,
    this.quantity,
    this.brandId,
    this.categoryId,
    this.imageFile,
  });

  @override
  List<Object?> get props => [
        productId,
        name,
        price,
        oldprice,
        description,
        specification,
        quantity,
        brandId,
        categoryId,
        imageFile
      ];
}

// Event xóa sản phẩm
class DeleteProduct extends ProductManagementEvent {
  final int productId;
  const DeleteProduct({required this.productId});
  @override
  List<Object?> get props => [productId];
}
