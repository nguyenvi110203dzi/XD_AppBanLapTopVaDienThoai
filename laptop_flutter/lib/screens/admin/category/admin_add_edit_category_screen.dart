// lib/screens/admin/category/admin_add_edit_category_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
// Import BLoC, Model, Repo của Category
import 'package:laptop_flutter/blocs/admin_management/category_management/category_management_bloc.dart';
import 'package:laptop_flutter/models/category.dart';
import 'package:laptop_flutter/repositories/category_repository.dart';

class AdminAddEditCategoryScreen extends StatefulWidget {
  final Category? category; // Danh mục cần sửa (null nếu thêm mới)

  const AdminAddEditCategoryScreen({super.key, this.category});

  @override
  State<AdminAddEditCategoryScreen> createState() =>
      _AdminAddEditCategoryScreenState();
}

class _AdminAddEditCategoryScreenState
    extends State<AdminAddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImageFile;
  String? _initialImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.category?.name ?? ''); // Lấy tên category
    _initialImageUrl = widget.category?.image; // Lấy ảnh category
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedXFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedXFile != null) {
      setState(() {
        _selectedImageFile = File(pickedXFile.path);
        _initialImageUrl = null;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final categoryName = _nameController.text.trim();
      final categoryBloc =
          context.read<CategoryManagementBloc>(); // Lấy Category BLoC

      if (widget.category == null) {
        // Thêm mới Category
        categoryBloc.add(AddCategory(
          name: categoryName,
          imageFile: _selectedImageFile,
        ));
      } else {
        // Sửa Category
        categoryBloc.add(UpdateCategory(
          id: widget.category!.id,
          name: categoryName,
          imageFile: _selectedImageFile,
        ));
      }

      // Lắng nghe kết quả để đóng màn hình
      categoryBloc.stream.listen((state) {
        if (mounted) {
          if (state is CategoryOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            Navigator.of(context).pop();
          } else if (state is CategoryOperationFailure) {
            setState(() {
              _isLoading = false;
            });
          } else if (state is! CategoryOperationInProgress) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy base URL từ CategoryRepository (thông qua AuthRepo được inject vào nó)
    final String baseUrl =
        context.read<CategoryRepository>().authRepository.baseUrl;
    final bool isEditMode = widget.category != null;
    final String appBarTitle =
        isEditMode ? 'Sửa Danh mục' : 'Thêm Danh mục'; // Title
    final String buttonTitle =
        isEditMode ? 'LƯU THAY ĐỔI' : 'THÊM DANH MỤC'; // Text nút

    Widget imagePreviewWidget() {
      ImageProvider? imageProvider;
      if (_selectedImageFile != null) {
        imageProvider = FileImage(_selectedImageFile!);
      } else if (_initialImageUrl != null && _initialImageUrl!.isNotEmpty) {
        final imageUrl = _initialImageUrl!.startsWith('http')
            ? _initialImageUrl!
            : baseUrl + _initialImageUrl!;
        imageProvider = NetworkImage(imageUrl);
      }
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          image: imageProvider != null
              ? DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  // Xử lý lỗi tải ảnh mạng
                  onError: (exception, stackTrace) {
                    print("Error loading image: $exception");
                    // Có thể hiển thị placeholder lỗi ở đây nếu muốn
                  },
                )
              : null, // Không có image nếu chưa có ảnh
        ),
        // Hiển thị icon placeholder nếu không có ảnh
        child: imageProvider == null
            ? const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey))
            : null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Tên Danh mục ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục', // Label
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined), // Icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên danh mục';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Chọn/Hiển thị Ảnh ---
              Text('Ảnh danh mục:',
                  style: Theme.of(context).textTheme.titleMedium), // Label ảnh
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  imagePreviewWidget(), // Hiển thị ảnh đã chọn hoặc ảnh cũ
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Nút Submit ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(buttonTitle), // Text nút
              ),
            ],
          ),
        ),
      ),
    );
  }
}
