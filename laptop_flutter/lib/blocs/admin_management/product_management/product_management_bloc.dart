import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart'; // Cần cho XFile
// Import thêm Brand và Category repo nếu cần lấy list cho dropdown
import 'package:laptop_flutter/models/brand.dart';
import 'package:laptop_flutter/models/category.dart';
import 'package:laptop_flutter/models/product.dart'; // Import model
import 'package:laptop_flutter/repositories/brand_repository.dart';
import 'package:laptop_flutter/repositories/category_repository.dart';
import 'package:laptop_flutter/repositories/product_repository.dart'; // Import repo

part 'product_management_event.dart';
part 'product_management_state.dart';

class ProductManagementBloc
    extends Bloc<ProductManagementEvent, ProductManagementState> {
  final ProductRepository _productRepository;
  final BrandRepository _brandRepository;
  final CategoryRepository _categoryRepository;

  // Biến tạm để lưu trữ danh sách sản phẩm, brand, category đã load
  // Giúp giữ lại danh sách khi thao tác thêm/sửa/xóa lỗi
  List<ProductModel> _currentProducts = [];
  List<Brand> _currentBrands = [];
  List<Category> _currentCategories = [];

  ProductManagementBloc({
    required ProductRepository productRepository,
    required BrandRepository brandRepository, // Inject nếu cần
    required CategoryRepository categoryRepository, // Inject nếu cần
  })  : _productRepository = productRepository,
        _brandRepository = brandRepository,
        _categoryRepository = categoryRepository,
        super(ProductManagementInitial()) {
    on<LoadAdminProducts>(_onLoadAdminProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  // Xử lý LoadAdminProducts
  Future<void> _onLoadAdminProducts(
      LoadAdminProducts event, Emitter<ProductManagementState> emit) async {
    print("[ProductMgmtBloc] Loading Admin Products...");
    emit(ProductManagementLoading());
    try {
      // Load đồng thời products, brands, categories nếu cần cho form/dropdown
      final results = await Future.wait([
        _productRepository.getAllProducts(), // Hoặc API riêng cho admin nếu có
        _brandRepository.getBrands(),
        _categoryRepository.getCategories(),
      ]);

      final products = results[0] as List<ProductModel>;
      final brands = results[1] as List<Brand>;
      final categories = results[2] as List<Category>;

      // Lưu lại danh sách hiện tại
      _currentProducts = products;
      _currentBrands = brands;
      _currentCategories = categories;

      emit(ProductManagementLoaded(products, brands, categories));
      print("[ProductMgmtBloc] Admin Products Loaded: ${products.length}");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[ProductMgmtBloc] Load Admin Products Failed: $error");
      emit(ProductManagementFailure(error));
    }
  }

  // Xử lý AddProduct
  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductManagementState> emit) async {
    print("[ProductMgmtBloc] Adding Product: ${event.name}");
    // Không emit Loading để UI không bị mất list
    try {
      await _productRepository.createProduct(
        name: event.name,
        price: event.price,
        oldprice: event.oldprice,
        description: event.description,
        specification: event.specification,
        quantity: event.quantity,
        brandId: event.brandId,
        categoryId: event.categoryId,
        imageFile: event.imageFile,
      );
      emit(
          const ProductManagementOperationSuccess('Thêm sản phẩm thành công!'));
      add(LoadAdminProducts()); // Tải lại toàn bộ dữ liệu (products, brands, categories)
      print("[ProductMgmtBloc] Add Product Success, reloading data.");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[ProductMgmtBloc] Add Product Failed: $error");
      emit(ProductManagementOperationFailure(error));
      // Emit lại state Loaded cũ để giữ danh sách trên UI
      if (_currentProducts.isNotEmpty) {
        // Chỉ emit lại nếu đã có dữ liệu cũ
        emit(ProductManagementLoaded(
            _currentProducts, _currentBrands, _currentCategories));
      }
    }
  }

  // Xử lý UpdateProduct
  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductManagementState> emit) async {
    print("[ProductMgmtBloc] Updating Product ID: ${event.productId}");
    try {
      await _productRepository.updateProduct(
        event.productId,
        name: event.name,
        price: event.price,
        oldprice: event.oldprice,
        description: event.description,
        specification: event.specification,
        quantity: event.quantity,
        brandId: event.brandId,
        categoryId: event.categoryId,
        imageFile: event.imageFile,
      );
      emit(const ProductManagementOperationSuccess(
          'Cập nhật sản phẩm thành công!'));
      add(LoadAdminProducts());
      print("[ProductMgmtBloc] Update Product Success, reloading data.");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[ProductMgmtBloc] Update Product Failed: $error");
      emit(ProductManagementOperationFailure(error));
      if (_currentProducts.isNotEmpty) {
        emit(ProductManagementLoaded(
            _currentProducts, _currentBrands, _currentCategories));
      }
    }
  }

  // Xử lý DeleteProduct
  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductManagementState> emit) async {
    print("[ProductMgmtBloc] Deleting Product ID: ${event.productId}");
    try {
      await _productRepository.deleteProduct(event.productId);
      emit(const ProductManagementOperationSuccess('Xóa sản phẩm thành công!'));
      add(LoadAdminProducts());
      print("[ProductMgmtBloc] Delete Product Success, reloading data.");
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      print("[ProductMgmtBloc] Delete Product Failed: $error");
      emit(ProductManagementOperationFailure(error));
      if (_currentProducts.isNotEmpty) {
        emit(ProductManagementLoaded(
            _currentProducts, _currentBrands, _currentCategories));
      }
    }
  }
}
