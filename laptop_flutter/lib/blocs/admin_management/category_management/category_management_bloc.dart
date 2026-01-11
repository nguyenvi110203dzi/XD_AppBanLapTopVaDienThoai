import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../models/category.dart'; // Import model Category
import '../../../repositories/category_repository.dart'; // Import repo Category

part 'category_management_event.dart';
part 'category_management_state.dart';

class CategoryManagementBloc
    extends Bloc<CategoryManagementEvent, CategoryManagementState> {
  final CategoryRepository categoryRepository; // Sử dụng CategoryRepository

  CategoryManagementBloc({required this.categoryRepository})
      : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryManagementState> emit) async {
    emit(CategoryLoading());
    try {
      final categories =
          await categoryRepository.getCategories(); // Gọi hàm repo tương ứng
      emit(CategoryLoadSuccess(categories)); // Emit state tương ứng
    } catch (e) {
      emit(CategoryLoadFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAddCategory(
      AddCategory event, Emitter<CategoryManagementState> emit) async {
    final currentState = state;
    List<Category> currentCategories = [];
    if (currentState is CategoryLoadSuccess) {
      currentCategories = currentState.categories;
    }

    emit(CategoryOperationInProgress());
    try {
      await categoryRepository.createCategory(
          name: event.name, imageFile: event.imageFile); // Gọi hàm repo
      emit(const CategoryOperationSuccess(
          'Thêm danh mục thành công!')); // Thông báo
      add(LoadCategories()); // Tải lại danh sách
    } catch (e) {
      emit(CategoryOperationFailure(
          e.toString().replaceFirst('Exception: ', '')));
      if (currentCategories.isNotEmpty) {
        emit(CategoryLoadSuccess(currentCategories));
      } else if (currentState is CategoryInitial ||
          currentState is CategoryLoadFailure) {
        emit(CategoryInitial());
      }
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<CategoryManagementState> emit) async {
    final currentState = state;
    List<Category> currentCategories = [];
    if (currentState is CategoryLoadSuccess) {
      currentCategories = currentState.categories;
    }

    emit(CategoryOperationInProgress());
    try {
      await categoryRepository.updateCategory(
          id: event.id,
          name: event.name,
          imageFile: event.imageFile); // Gọi hàm repo
      emit(const CategoryOperationSuccess(
          'Cập nhật danh mục thành công!')); // Thông báo
      add(LoadCategories()); // Tải lại
    } catch (e) {
      emit(CategoryOperationFailure(
          e.toString().replaceFirst('Exception: ', '')));
      if (currentCategories.isNotEmpty) {
        emit(CategoryLoadSuccess(currentCategories));
      } else if (currentState is CategoryInitial ||
          currentState is CategoryLoadFailure) {
        emit(CategoryInitial());
      }
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<CategoryManagementState> emit) async {
    final currentState = state;
    List<Category> currentCategories = [];
    if (currentState is CategoryLoadSuccess) {
      currentCategories = currentState.categories;
    }
    emit(CategoryOperationInProgress());
    try {
      await categoryRepository.deleteCategory(event.id); // Gọi hàm repo
      emit(const CategoryOperationSuccess(
          'Xóa danh mục thành công!')); // Thông báo
      add(LoadCategories()); // Tải lại
    } catch (e) {
      emit(CategoryOperationFailure(
          e.toString().replaceFirst('Exception: ', '')));
      if (currentCategories.isNotEmpty) {
        emit(CategoryLoadSuccess(currentCategories));
      } else if (currentState is CategoryInitial ||
          currentState is CategoryLoadFailure) {
        emit(CategoryInitial());
      }
    }
  }
}
