import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Có thể đặt màu nền giống theme chính của bạn
      backgroundColor: Colors.orange[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Tùy chọn: Thêm Logo của bạn ---
            Image.asset(
              'assets/logos/your_logo.png', // Thay bằng đường dẫn logo của bạn
              height: 100, // Điều chỉnh kích thước logo
            ),
            const SizedBox(height: 30),

            // --- Vòng tròn Loading ---
            const CircularProgressIndicator(
              // Có thể tùy chỉnh màu sắc
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),

            // --- Tùy chọn: Thêm tên ứng dụng ---
            const SizedBox(height: 20),
            Text(
              'Laptop Shop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
