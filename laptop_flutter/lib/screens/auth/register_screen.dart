import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart'; // Import AuthBloc để lấy instance
import '../../blocs/register/register_bloc.dart'; // Import RegisterBloc
import '../../repositories/auth_repository.dart';
import 'login_screen.dart'; // Import AuthRepo để tạo RegisterBloc

// Import LoginScreen để điều hướng
// import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Key để quản lý Form
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(); // Thêm nếu có trường SĐT

  bool _isPasswordVisible = false; // State quản lý ẩn/hiện mật khẩu

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Hàm validate Email đơn giản
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Địa chỉ email không hợp lệ';
    }
    return null;
  }

  // Hàm validate Mật khẩu đơn giản
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  // Hàm validate Tên đơn giản
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Cung cấp RegisterBloc cục bộ cho màn hình này
    return BlocProvider(
      create: (context) => RegisterBloc(
        authRepository:
            context.read<AuthRepository>(), // Lấy AuthRepo từ context cha
        authBloc: context.read<AuthBloc>(), // Lấy AuthBloc từ context cha
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký'),
          // actions: [IconButton(onPressed: (){}, icon: Icon(Icons.search))] // Bỏ icon search nếu không cần
        ),
        body: BlocListener<RegisterBloc, RegisterState>(
          // Lắng nghe state thay đổi để xử lý sau khi đăng ký
          listener: (context, state) {
            if (state is RegisterSuccess) {
              // Đăng ký thành công -> Quay lại màn hình trước hoặc đi đến Home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đăng ký thành công!'),
                    backgroundColor: Colors.green),
              );
              Navigator.pop(
                  context); // Quay lại màn hình trước đó (ví dụ: Account hoặc Login)
              // Hoặc xóa stack và đi đến Home nếu muốn tự động đăng nhập
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else if (state is RegisterFailure) {
              // Đăng ký thất bại -> Hiển thị lỗi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Đăng ký thất bại: ${state.error}'),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            // Cho phép cuộn nếu nội dung dài
            padding: const EdgeInsets.all(24.0),
            child: Form(
              // Bọc các trường nhập liệu bằng Form
              key: _formKey, // Gán key cho Form
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Kéo giãn các thành phần con
                children: [
                  // Trường nhập Tên
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.check_circle,
                          color: Colors
                              .green), // Hiện tick khi hợp lệ (cần logic thêm)
                    ),
                    validator: _validateName,
                    textInputAction:
                        TextInputAction.next, // Chuyển sang trường tiếp theo
                  ),
                  const SizedBox(height: 16),

                  // Trường nhập Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Trường nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible, // Ẩn/hiện mật khẩu
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        // Nút ẩn/hiện mật khẩu
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible; // Đảo trạng thái hiển thị
                          });
                        },
                      ),
                    ),
                    validator: _validatePassword,
                    textInputAction:
                        TextInputAction.done, // Hoàn thành nhập liệu
                    onFieldSubmitted: (_) {
                      // Xử lý submit khi nhấn Done trên bàn phím
                      final isValid =
                          _formKey.currentState?.validate() ?? false;
                      if (isValid) {
                        context.read<RegisterBloc>().add(RegisterSubmitted(
                              name: _nameController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                            ));
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Trường nhập Email
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.check_circle,
                          color: Colors
                              .green), // Hiện tick khi hợp lệ (cần logic thêm)
                    ),
                    validator: _validateName,
                    textInputAction:
                        TextInputAction.next, // Chuyển sang trường tiếp theo
                  ),
                  const SizedBox(height: 16),

                  // Link đến trang Đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bạn đã có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          print('Navigate to Login');
                          // Đóng màn hình hiện tại và đi đến Login
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => LoginScreen()));
                          Navigator.pop(
                              context); // Đơn giản là quay lại nếu đến từ Account/Login
                        },
                        child: Text('Đăng nhập'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nút Đăng ký
                  BlocBuilder<RegisterBloc, RegisterState>(
                    builder: (context, state) {
                      // Lấy trạng thái loading từ state
                      bool isLoading = state is RegisterLoading;

                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // Vô hiệu hóa nút khi đang loading
                                // Validate Form trước khi gửi event
                                final isValid =
                                    _formKey.currentState?.validate() ?? false;
                                if (isValid) {
                                  // Lấy dữ liệu từ controllers và gửi event
                                  context
                                      .read<RegisterBloc>()
                                      .add(RegisterSubmitted(
                                        name: _nameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        password: _passwordController
                                            .text, // Mật khẩu không nên trim
                                        phone: _phoneController.text
                                            .trim(), // Lấy phone nếu có
                                      ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        // Hiển thị loading hoặc text tùy state
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('ĐĂNG KÝ'),
                      );
                    },
                  ),

                  // Tùy chọn: Đăng ký bằng MXH
                  const SizedBox(height: 32),
                  const Center(child: Text('Đăng ký bằng tài khoản xã hội')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          onPressed: () {},
                          icon: Image.asset('assets/images/icon/google.png',
                              height: 40)), // Cần có ảnh icon google
                      const SizedBox(width: 24),
                      IconButton(
                          onPressed: () {},
                          icon: Image.asset('assets/images/icon/facebook.png',
                              height: 40)), // Cần có ảnh icon facebook
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
