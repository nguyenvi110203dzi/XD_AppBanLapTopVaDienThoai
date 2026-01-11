import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:laptop_flutter/models/bao_hanh_model.dart';

import '../config/app_constants.dart'; // Đảm bảo đường dẫn đúng

class BaoHanhRepository {
  final String _baseUrl = AppConstants.baseUrl; // Hoặc từ một config file

  Future<List<BaoHanhModel>> searchBaoHanhByPhone(
      String phoneNumber, String token) async {
    if (phoneNumber.isEmpty) {
      return [];
    }
    final response = await http.get(
      Uri.parse('$_baseUrl/api/baohanh/search?phone=$phoneNumber'),
      headers: {
        'Content-Type':
            'application/json; charset=UTF-8', // Quan trọng để có UTF-8
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) =>
              BaoHanhModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      print(
          'Lỗi API tìm kiếm bảo hành: ${response.statusCode} - ${response.body}');
      String errorMessage = 'Không thể tìm kiếm thông tin bảo hành.';
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorBody['message'] != null) {
          errorMessage += ' ${errorBody['message']}';
        }
      } catch (e) {
        // ignore
      }
      throw Exception(errorMessage);
    }
  }

  // TODO: Thêm các hàm khác: getAllBaoHanh, getBaoHanhById, createBaoHanh, updateBaoHanh
  // Ví dụ:
  Future<List<BaoHanhModel>> getAllBaoHanh(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/baohanh'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) =>
              BaoHanhModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Không thể tải danh sách bảo hành. Lỗi: ${response.body}');
    }
  }

  Future<List<BaoHanhModel>> searchBaoHanhByName(
      String customerName, String token) async {
    if (customerName.isEmpty) {
      return []; // Trả về danh sách rỗng nếu tên tìm kiếm rỗng
    }
    // Backend của bạn (baoHanhController.js -> searchBaoHanh) tìm theo `req.query.name`
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/api/baohanh/search?name=${Uri.encodeComponent(customerName)}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Gửi token admin
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body
          .map((dynamic item) =>
              BaoHanhModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return []; // Không tìm thấy kết quả
    } else {
      // Xử lý các lỗi khác từ server
      String errorMessage = 'Lỗi khi tìm kiếm thông tin bảo hành.';
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorBody != null && errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        } else {
          errorMessage = 'Lỗi ${response.statusCode}: ${response.reasonPhrase}';
        }
      } catch (e) {
        errorMessage =
            'Lỗi ${response.statusCode}: ${response.reasonPhrase} (Không thể parse lỗi chi tiết)';
      }
      print('Lỗi API tìm kiếm bảo hành theo tên: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}
