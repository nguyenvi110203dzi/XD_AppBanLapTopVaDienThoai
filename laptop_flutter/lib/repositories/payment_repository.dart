// TODO Implement this library.
import 'dart:convert';

import 'package:http/http.dart' as http;

// Import các thành phần cần thiết khác (ví dụ: AuthRepository để lấy token)
import '../config/app_constants.dart';
import 'auth_repository.dart';

class PaymentRepository {
  // !! QUAN TRỌNG: Đảm bảo baseUrl đúng !!
  // final String baseUrl = "http://10.0.2.2:3000"; // Cho Android Emulator
  final String baseUrl = AppConstants.baseUrl; // IP từ log lỗi trước đó

  final AuthRepository _authRepository;

  PaymentRepository({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Hàm helper lấy Token
  Future<String> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null) {
      throw Exception(
          'Auth Error: Token not found. User might not be logged in.');
    }
    return token;
  }

  // Hàm gọi API backend để tạo URL thanh toán VNPAY
  Future<String> createVnpayUrl({
    required int orderId,
    required int amount, // Số tiền đơn vị VND (backend sẽ *100)
    String? orderDescription,
    String? bankCode, // Mã ngân hàng (tùy chọn)
    String locale = 'vn', // Ngôn ngữ (vn/en)
  }) async {
    final token = await _getToken(); // Lấy token xác thực
    final url = Uri.parse('$baseUrl/api/payment/vnpay/create_url');
    print('[PaymentRepo] Calling POST $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Gửi token
        },
        body: jsonEncode(<String, dynamic>{
          'orderId': orderId,
          'amount': amount, // Gửi số tiền VND
          'orderDescription': orderDescription,
          'bankCode': bankCode, // Sẽ là null nếu không truyền
          'locale': locale,
        }),
      );

      print('[PaymentRepo] Create VNPAY URL Status: ${response.statusCode}');
      final responseBodyString = utf8.decode(response.bodyBytes);
      print('[PaymentRepo] Create VNPAY URL Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(responseBodyString);
        if (responseBody['paymentUrl'] != null &&
            responseBody['paymentUrl'] is String) {
          return responseBody['paymentUrl']; // Trả về URL thanh toán
        } else {
          throw Exception(
              'Invalid response format: paymentUrl not found or not a string.');
        }
      } else {
        // Xử lý lỗi từ server
        String errorMessage =
            'Lỗi tạo URL thanh toán (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[PaymentRepo] Error creating VNPAY URL: $e');
      throw Exception(
          'Không thể tạo link thanh toán VNPAY: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

// TODO: Thêm các hàm khác liên quan đến payment nếu cần
}
