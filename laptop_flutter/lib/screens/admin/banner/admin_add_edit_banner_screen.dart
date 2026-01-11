import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
// Import BLoC, Model, Repo của Banner
import 'package:laptop_flutter/blocs/admin_management/banner_management/banner_management_bloc.dart';
import 'package:laptop_flutter/models/banner.dart';

import '../../../repositories/auth_repository.dart';

class AdminAddEditBannerScreen extends StatefulWidget {
  final BannerModel? banner; // Banner cần sửa (null nếu thêm mới)

  const AdminAddEditBannerScreen({super.key, this.banner});

  @override
  State<AdminAddEditBannerScreen> createState() =>
      _AdminAddEditBannerScreenState();
}

class _AdminAddEditBannerScreenState extends State<AdminAddEditBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImageFile;
  String? _initialImageUrl;
  bool _isActive = true; // Trạng thái mặc định là Active (1)

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.banner?.name ?? ''); // Tên banner
    _initialImageUrl = widget.banner?.image; // Ảnh banner
    _isActive = widget.banner?.status == 1 ??
        true; // Lấy status, mặc định true nếu thêm mới
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
    // Kiểm tra xem có ảnh không (quan trọng với banner)
    if (_selectedImageFile == null && widget.banner?.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ảnh cho banner.'),
            backgroundColor: Colors.red),
      );
      return; // Dừng nếu không có ảnh khi thêm mới
    }

    if (_formKey.currentState!.validate()) {
      final bannerName = _nameController.text.trim();
      final bannerStatus =
          _isActive ? 1 : 0; // Chuyển bool thành int (1 hoặc 0)
      final bannerBloc =
          context.read<BannerManagementBloc>(); // Lấy Banner BLoC

      if (widget.banner == null) {
        // Thêm mới Banner
        bannerBloc.add(AddBanner(
          name: bannerName.isEmpty ? null : bannerName, // Gửi null nếu tên rỗng
          status: bannerStatus,
          imageFile: _selectedImageFile, // Ảnh là bắt buộc khi thêm?
        ));
      } else {
        // Sửa Banner
        bannerBloc.add(UpdateBanner(
          id: widget.banner!.id,
          name: bannerName.isEmpty ? null : bannerName, // Gửi null nếu tên rỗng
          status: bannerStatus,
          imageFile: _selectedImageFile, // Gửi ảnh mới nếu có
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String baseUrl = context.read<AuthRepository>().baseUrl;
    final bool isEditMode = widget.banner != null;
    final String appBarTitle = isEditMode ? 'Sửa Banner' : 'Thêm Banner';
    final String buttonTitle = isEditMode ? 'LƯU THAY ĐỔI' : 'THÊM BANNER';

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
      body: BlocListener<BannerManagementBloc, BannerManagementState>(
        listener: (context, state) {
          if (state is BannerOperationSuccess) {
            Navigator.of(context).pop(); // Đóng màn hình khi thành công
            // SnackBar thành công nên hiển thị ở màn hình danh sách sau khi pop
          } else if (state is BannerOperationFailure) {
            // Hiển thị lỗi ngay tại đây
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Lỗi: ${state.error}'),
                backgroundColor: Colors.red));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Tên Banner (Tùy chọn) ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên banner (Tùy chọn)', // Cho phép bỏ trống
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  // Không cần validator vì tên là tùy chọn
                ),
                const SizedBox(height: 20),

                // --- Chọn/Hiển thị Ảnh ---
                Text('Ảnh banner (Bắt buộc):',
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
                const SizedBox(height: 20),

                // --- Trạng thái (Status) ---
                SwitchListTile(
                  // Dùng SwitchListTile cho đơn giản
                  title: const Text('Trạng thái hoạt động'),
                  value: _isActive,
                  onChanged: (bool value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  secondary: Icon(
                      _isActive ? Icons.check_circle : Icons.cancel_outlined,
                      color: _isActive ? Colors.green : Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- Nút Submit ---
                BlocBuilder<BannerManagementBloc, BannerManagementState>(
                  builder: (context, state) {
                    bool isLoading = state is BannerOperationInProgress;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(buttonTitle),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
