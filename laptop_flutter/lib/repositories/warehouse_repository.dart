// lib/repositories/warehouse_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:laptop_flutter/models/inventory_transaction_model.dart'; // Đảm bảo import này đúng nếu bạn trả về hoặc sử dụng

import '../config/app_constants.dart';
import '../models/product.dart';
import 'auth_repository.dart';

class WarehouseRepository {
  final String _baseUrl = AppConstants.baseUrl;
  final AuthRepository authRepository;

  WarehouseRepository({required this.authRepository});

  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  // VVV PHƯƠNG THỨC NÀY PHẢI TỒN TẠI VÀ ĐÚNG TÊN VVV
  Future<ProductModel> importStock({
    // Đảm bảo tên là 'importStock'
    required int productId,
    required int quantity,
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Yêu cầu xác thực.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/warehouse/import'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // Backend trả về { message: 'Nhập kho thành công.', product: updatedProduct }
      // Nên bạn cần lấy product từ data['product']
      if (data['product'] != null) {
        return ProductModel.fromJson(data['product']);
      } else {
        throw Exception(
            'Dữ liệu sản phẩm không tìm thấy trong phản hồi từ API nhập kho.');
      }
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi nhập kho');
    }
  }
  // ^^^----------------------------------------------------^^^

  Future<ProductModel> exportStock({
    required int productId,
    required int quantity,
    required String reason,
    String? notes,
  }) async {
    // ... (code của bạn)
    final token = await _getToken();
    if (token == null) throw Exception('Yêu cầu xác thực.');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/warehouse/export'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
        'reason': reason,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['product'] != null) {
        // Kiểm tra tương tự như importStock
        return ProductModel.fromJson(data['product']);
      } else {
        throw Exception(
            'Dữ liệu sản phẩm không tìm thấy trong phản hồi từ API xuất kho.');
      }
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi xuất kho');
    }
  }

  Future<int> getOverallProductQuantity() async {
    // ... (code của bạn)
    final token = await _getToken();
    if (token == null) throw Exception('Yêu cầu xác thực.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/warehouse/products/total-quantity'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['total_quantity'] ?? 0;
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi lấy tổng số lượng sản phẩm');
    }
  }

  Future<List<InventoryTransactionModel>> getProductStockHistory(
      int productId) async {
    // ... (code của bạn)
    final token = await _getToken();
    if (token == null) throw Exception('Yêu cầu xác thực.');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/warehouse/products/$productId/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> historyList = data['history'];
      // Cần đảm bảo InventoryTransactionModel.fromJson xử lý đúng cấu trúc User từ API
      return historyList
          .map((item) => InventoryTransactionModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 404) {
      throw Exception('Sản phẩm không tồn tại.');
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Lỗi lấy lịch sử kho');
    }
  }
}
