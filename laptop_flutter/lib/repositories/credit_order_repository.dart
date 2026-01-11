import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:laptop_flutter/config/app_constants.dart';
import 'package:laptop_flutter/models/credit_order.dart';
import 'package:laptop_flutter/repositories/auth_repository.dart';

class CreditOrderRepository {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthRepository authRepository;

  CreditOrderRepository({required this.authRepository});

  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  // API cho Khách hàng (role=2)
  Future<CreditOrderModel> createCreditOrder({
    required List<Map<String, dynamic>>
        items, // [{'product_id': id, 'quantity': sl}]
    String? note,
    DateTime? dueDate,
  }) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Người dùng chưa đăng nhập hoặc không có quyền.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/credit-orders'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'items': items,
        'note': note,
        'due_date': dueDate?.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      final responseBody = utf8.decode(response.bodyBytes);
      print('============================================');
      print('RAW JSON RESPONSE for Create Credit Order:');
      print(responseBody);
      print('============================================');
      try {
        return CreditOrderModel.fromJson(jsonDecode(responseBody));
      } catch (e, stackTrace) {
        print('Error parsing CreditOrderModel: $e');
        print(
            'StackTrace: $stackTrace'); // In stack trace để xem chi tiết lỗi parse
        rethrow; // Ném lại lỗi để BLoC xử lý
      }
      //return CreditOrderModel.fromJson(
      //    jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi tạo đơn hàng công nợ');
    }
  }

  Future<List<CreditOrderModel>> getMyCreditOrders({int? status}) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Người dùng chưa đăng nhập hoặc không có quyền.');

    String url = '$_baseUrl/api/credit-orders/my-history';
    if (status != null) {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) => CreditOrderModel.fromJson(item))
          .toList();
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi lấy lịch sử đơn công nợ');
    }
  }

  Future<CreditOrderModel> getMyCreditOrderDetail(int orderId) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Người dùng chưa đăng nhập hoặc không có quyền.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/credit-orders/my-history/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return CreditOrderModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy đơn hàng công nợ.');
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi lấy chi tiết đơn công nợ');
    }
  }

  // API cho Admin
  Future<List<CreditOrderModel>> getAllCreditOrdersForAdmin(
      {int? status, int? userId}) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Admin chưa đăng nhập hoặc không có quyền.');

    var queryParameters = <String, String>{};
    if (status != null) {
      queryParameters['status'] = status.toString();
    }
    if (userId != null) {
      queryParameters['userId'] = userId.toString();
    }
    // Thêm sortBy, sortOrder nếu cần

    final uri = Uri.parse('$_baseUrl/api/credit-orders/admin').replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) => CreditOrderModel.fromJson(item))
          .toList();
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Lỗi lấy danh sách đơn công nợ (Admin)');
    }
  }

  Future<CreditOrderModel> getCreditOrderDetailForAdmin(int orderId) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Admin chưa đăng nhập hoặc không có quyền.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/credit-orders/admin/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return CreditOrderModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy đơn hàng công nợ (Admin).');
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Lỗi lấy chi tiết đơn công nợ (Admin)');
    }
  }

  Future<CreditOrderModel> updateCreditOrderStatusForAdmin({
    required int orderId,
    int? status,
    DateTime? dueDate,
    String? note,
  }) async {
    final token = await _getToken();
    if (token == null)
      throw Exception('Admin chưa đăng nhập hoặc không có quyền.');

    final Map<String, dynamic> body = {};
    if (status != null) body['status'] = status;
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
    if (note != null) body['note'] = note;

    final response = await http.put(
      Uri.parse('$_baseUrl/api/credit-orders/admin/$orderId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return CreditOrderModel.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Lỗi cập nhật đơn hàng công nợ (Admin)');
    }
  }
}
