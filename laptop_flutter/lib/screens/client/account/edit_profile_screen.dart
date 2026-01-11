import 'dart:io'; // Cho File

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/profile_edit/profile_edit_bloc.dart';
import '../../../config/app_constants.dart';
import '../../../models/user.dart';
import '../../../repositories/auth_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _selectedAvatarPath; // Lưu đường dẫn ảnh mới chọn
  final ImagePicker _picker = ImagePicker(); // Đối tượng để chọn ảnh

  UserModel? _currentUser; // Lưu user hiện tại để lấy thông tin ban đầu

  @override
  void initState() {
    super.initState();
    // Lấy user hiện tại từ AuthBloc để điền vào form
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
    } else {
      // Trường hợp hiếm: vào màn hình này mà chưa đăng nhập? -> quay lại
      // Hoặc hiển thị lỗi và không cho sửa
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Lỗi: Không tìm thấy thông tin người dùng.')));
        }
      });
    }

    _nameController = TextEditingController(text: _currentUser?.name ?? '');
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
    _phoneController =
        TextEditingController(text: _currentUser?.phone?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Hàm chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // Chọn từ thư viện
        imageQuality: 80, // Giảm chất lượng ảnh một chút
        maxWidth: 800, // Giảm kích thước ảnh
      );

      if (pickedFile != null) {
        setState(() {
          _selectedAvatarPath = pickedFile.path; // Lưu đường dẫn file đã chọn
          print("Image picked: $_selectedAvatarPath");
        });
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy user hiện tại để hiển thị avatar cũ (nếu có)
    final initialAvatar = _currentUser?.avatar;

    return BlocProvider(
      create: (context) => ProfileEditBloc(
        authRepository: context.read<AuthRepository>(),
        authBloc: context.read<
            AuthBloc>(), // Cần để cập nhật lại AuthBloc sau khi thành công
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa hồ sơ'),
          actions: [
            // Nút Lưu
            BlocBuilder<ProfileEditBloc, ProfileEditState>(
              builder: (context, state) {
                if (state is ProfileEditInProgress) {
                  return const Padding(
                    // Hiển thị loading thay nút
                    padding: EdgeInsets.only(right: 16.0),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Lưu thay đổi',
                  onPressed: () {
                    // Validate form
                    if (_formKey.currentState?.validate() ?? false) {
                      // Gửi event submit
                      context.read<ProfileEditBloc>().add(ProfileEditSubmitted(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            avatarImagePath:
                                _selectedAvatarPath, // Truyền đường dẫn ảnh mới nếu có
                          ));
                    }
                  },
                );
              },
            )
          ],
        ),
        body: BlocListener<ProfileEditBloc, ProfileEditState>(
          listener: (context, state) {
            if (state is ProfileEditSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Cập nhật hồ sơ thành công!'),
                    backgroundColor: Colors.green),
              );
              // Tự động quay lại màn hình trước đó sau khi thành công
              Navigator.of(context).pop();
            } else if (state is ProfileEditFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Cập nhật thất bại: ${state.error}'),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- Phần Avatar ---
                  Stack(
                    // Dùng Stack để đặt nút sửa lên trên avatar
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        // Hiển thị ảnh mới chọn (Image.file) hoặc ảnh cũ (Image.asset)
                        backgroundImage: _selectedAvatarPath != null
                            ? FileImage(File(_selectedAvatarPath!))
                                as ImageProvider // Dùng FileImage
                            : (initialAvatar != null && initialAvatar.isNotEmpty
                                ? NetworkImage(
                                    AppConstants.baseUrl + initialAvatar)
                                : null), // Dùng AssetImage cho avatar cũ
                        child: (_selectedAvatarPath == null &&
                                initialAvatar == null)
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.white)
                            : null, // Không cần icon nếu có ảnh
                      ),
                      // Nút chọn ảnh mới
                      Material(
                        // Dùng Material để có hiệu ứng ripple
                        color: Theme.of(context).primaryColor,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: _pickImage,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Các trường thông tin ---
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty)
                        return 'Vui lòng nhập tên';
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    readOnly: true, // <<< KHÔNG CHO SỬA EMAIL
                    style: TextStyle(
                        color: Colors.grey[600]), // Màu xám cho trường readonly
                    decoration: const InputDecoration(
                      labelText: 'Email (Không thể thay đổi)',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      filled: true, // Thêm nền nhẹ
                      fillColor: Color.fromARGB(255, 243, 243, 243),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // Có thể gọi submit form từ đây nếu muốn
                      // if (_formKey.currentState?.validate() ?? false) { ... }
                    },
                    // Thêm validator cho SĐT nếu cần
                  ),
                  const SizedBox(height: 32),
                  // Nút Lưu (đã chuyển lên AppBar actions)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
