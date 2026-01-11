import 'dart:io'; // Để sử dụng File

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:laptop_flutter/blocs/admin_management/brand_management/brand_management_bloc.dart'; // Import BLoC
import 'package:laptop_flutter/models/brand.dart'; // Import Model
import 'package:laptop_flutter/repositories/brand_repository.dart'; // Để lấy base URL

class AdminAddEditBrandScreen extends StatefulWidget {
  final Brand? brand; // Thương hiệu cần sửa (null nếu là thêm mới)

  const AdminAddEditBrandScreen({super.key, this.brand});

  @override
  State<AdminAddEditBrandScreen> createState() =>
      _AdminAddEditBrandScreenState();
}

class _AdminAddEditBrandScreenState extends State<AdminAddEditBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImageFile; // File ảnh đã chọn
  String? _initialImageUrl; // URL ảnh ban đầu (khi edit)
  bool _isLoading = false; // Trạng thái loading khi submit

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand?.name ?? '');
    _initialImageUrl = widget.brand?.image; // Lưu URL ảnh ban đầu nếu có
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? pickedXFile = await picker.pickImage(
        source: ImageSource.gallery); // Hoặc ImageSource.camera

    if (pickedXFile != null) {
      setState(() {
        _selectedImageFile = File(pickedXFile.path);
        _initialImageUrl = null; // Xóa ảnh ban đầu nếu chọn ảnh mới
        print("Image selected: ${pickedXFile.path}");
      });
    } else {
      print("No image selected.");
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Bắt đầu loading
      });

      final brandName = _nameController.text.trim();

      // Lấy BLoC từ context
      final brandBloc = context.read<BrandManagementBloc>();

      if (widget.brand == null) {
        // --- Chế độ Thêm mới ---
        brandBloc.add(AddBrand(
          name: brandName,
          imageFile: _selectedImageFile,
        ));
      } else {
        // --- Chế độ Sửa ---
        brandBloc.add(UpdateBrand(
          id: widget.brand!.id,
          name: brandName,
          imageFile: _selectedImageFile, // Gửi ảnh mới nếu có
        ));
      }

      // Lắng nghe kết quả từ BLoC để tắt loading và đóng màn hình
      // Sử dụng listen:true để chỉ lắng nghe 1 lần sau khi submit
      brandBloc.stream.listen((state) {
        if (mounted) {
          // Kiểm tra xem State còn tồn tại không
          if (state is BrandOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            Navigator.of(context)
                .pop(); // Đóng màn hình add/edit sau khi thành công
            // Thông báo thành công đã được xử lý ở màn hình danh sách
          } else if (state is BrandOperationFailure) {
            setState(() {
              _isLoading = false;
            });
            // Thông báo lỗi đã được xử lý ở màn hình danh sách, không cần pop()
          } else if (state is! BrandOperationInProgress) {
            // Nếu state khác đang xử lý mà không phải success/failure thì cũng tắt loading (phòng trường hợp)
            setState(() {
              _isLoading = false;
            });
          }
        }
      }, onError: (error) {
        // Xử lý lỗi stream nếu cần
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
    final String baseUrl = context
        .read<BrandRepository>()
        .authRepository
        .baseUrl; // Lấy base URL để hiển thị ảnh
    final bool isEditMode = widget.brand != null;
    final String appBarTitle =
        isEditMode ? 'Sửa Thương hiệu' : 'Thêm Thương hiệu';
    final String buttonTitle = isEditMode ? 'LƯU THAY ĐỔI' : 'THÊM THƯƠNG HIỆU';

    // Widget hiển thị ảnh (có thể tách thành widget riêng)
    Widget imagePreviewWidget() {
      ImageProvider? imageProvider;

      if (_selectedImageFile != null) {
        // Ưu tiên hiển thị ảnh mới chọn từ File
        print("Displaying selected file: ${_selectedImageFile!.path}");
        imageProvider = FileImage(_selectedImageFile!);
      } else if (_initialImageUrl != null && _initialImageUrl!.isNotEmpty) {
        // Hiển thị ảnh cũ từ URL nếu chưa chọn ảnh mới
        final imageUrl = _initialImageUrl!.startsWith('http')
            ? _initialImageUrl!
            : baseUrl + _initialImageUrl!;
        print("Displaying initial URL: $imageUrl");
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
              // --- Tên Thương hiệu ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thương hiệu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên thương hiệu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Chọn/Hiển thị Ảnh ---
              Text('Ảnh thương hiệu:',
                  style: Theme.of(context).textTheme.titleMedium),
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
                onPressed: _isLoading
                    ? null
                    : _submitForm, // Disable nút khi đang loading
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(buttonTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
