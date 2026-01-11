import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:laptop_flutter/screens/warehouse_staff/warehouse_staff_main_screen.dart'; // << THÊM IMPORT NÀY

import '../../blocs/auth/auth_bloc.dart'; // AuthBloc chung
import '../../blocs/login/login_bloc.dart'; // LoginBloc riêng
import '../../repositories/auth_repository.dart';
import '../admin/admin_main_screen.dart';
import '../client/credit_customer/credit_customer_main_screen.dart';
import '../client/main_screens.dart';
import 'register_screen.dart'; // Import RegisterScreen để điều hướng

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible =
      false; // Thêm state ẩn/hiện mật khẩu (dù mockup không có nhưng nên có)

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm validate Email (có thể dùng lại từ RegisterScreen)
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

  // Hàm validate Password (chỉ cần không rỗng)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        authRepository: context.read<AuthRepository>(),
        authBloc: context.read<AuthBloc>(), // Truyền AuthBloc chung vào
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng nhập'),
          // actions: [IconButton(onPressed: (){}, icon: Icon(Icons.search))] // Bỏ icon search
        ),
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              // Đăng nhập thành công -> Pop màn hình login
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đăng nhập thành công!'),
                    backgroundColor: Colors.green),
              );
              Navigator.of(context)
                  .pop(); // Quay lại màn hình trước đó (ví dụ: Account)
            } else if (state is LoginSuccessAdmin) {
              // Hiển thị Dialog hỏi người dùng
              showDialog(
                context: context,
                barrierDismissible:
                    false, // Không cho đóng dialog bằng cách bấm ra ngoài
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Xác nhận vai trò'),
                  content: const Text('Bạn muốn vào giao diện quản lý không?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Không'),
                      onPressed: () {
                        // Chọn "Không" -> Coi như User thường
                        // 1. Đóng dialog
                        Navigator.of(dialogContext).pop();
                        // 2. Cập nhật AuthBloc
                        context
                            .read<AuthBloc>()
                            .add(AuthLoggedIn(user: state.user));
                        // 3. Pop màn hình Login (giống user thường)
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => MainLayout()));
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đăng nhập thành công!'),
                              backgroundColor: Colors.green),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text('Có'),
                      onPressed: () {
                        // Chọn "Có" -> Vào trang Admin
                        // 1. Đóng dialog
                        Navigator.of(dialogContext).pop();
                        // 2. Cập nhật AuthBloc
                        context
                            .read<AuthBloc>()
                            .add(AuthLoggedIn(user: state.user));
                        // 3. Điều hướng đến màn hình Admin chính và xóa các màn hình cũ
                        print("Navigating to Admin Section");
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AdminMainScreen()), // <<< Điều hướng đến AdminMainScreen
                          (route) => false, // Xóa tất cả route trước đó
                        );
                      },
                    ),
                  ],
                ),
              );
            } else if (state is LoginSuccessCreditCustomer) {
              // Xử lý state mới
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Chào mừng khách hàng công nợ!'),
                    backgroundColor: Colors.teal),
              );
              // Điều hướng đến màn hình chính của khách hàng công nợ
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const CreditCustomerMainScreen()),
                  (route) => false);
            }
            // VVV THÊM ELSE IF NÀY VVV
            else if (state is LoginSuccessWarehouseStaff) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Đăng nhập thành công với vai trò Nhân viên kho!'),
                    backgroundColor: Colors.blueAccent),
              );
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) =>
                          const WarehouseStaffMainScreen()), // Điều hướng đến màn hình của NV Kho
                  (route) => false);
            }
            // ^^^ THÊM ELSE IF NÀY ^^^
            else if (state is LoginFailure) {
              // Đăng nhập thất bại -> Hiển thị lỗi
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Đăng nhập thất bại: ${state.error}'),
                    backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Trường nhập Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      // suffixIcon: Icon(Icons.check_circle, color: Colors.green), // Có thể thêm tick nếu muốn
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Trường nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
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
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: _validatePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // Xử lý submit từ bàn phím
                      final isValid =
                          _formKey.currentState?.validate() ?? false;
                      if (isValid) {
                        context.read<LoginBloc>().add(LoginSubmitted(
                              email: _emailController.text,
                              password: _passwordController.text,
                            ));
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  // Link Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Điều hướng đến màn hình Quên mật khẩu
                        print('Navigate to Forgot Password');
                      },
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập
                  BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      bool isLoading = state is LoginLoading;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                final isValid =
                                    _formKey.currentState?.validate() ?? false;
                                if (isValid) {
                                  context.read<LoginBloc>().add(LoginSubmitted(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('ĐĂNG NHẬP'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Link đến trang Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          print('Navigate to Register');
                          // Điều hướng sang Register
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()));
                        },
                        child: Text('Đăng ký ngay'),
                      ),
                    ],
                  ),

                  // Tùy chọn: Đăng nhập bằng MXH
                  // ... (Tương tự như màn hình đăng ký) ...
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
