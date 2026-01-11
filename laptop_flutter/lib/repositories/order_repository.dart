import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../models/order.dart'; // Import Order model (cần tạo hoặc đảm bảo đã có)
import 'auth_repository.dart'; // Cần để lấy token
// Import CartItem model nếu cần dùng ở đây, hoặc chỉ cần Map
// import '../models/cart_item.dart';

class OrderRepository {
  final String baseUrl = AppConstants.baseUrl; // Thay base URL
  final AuthRepository authRepository; // Inject AuthRepository để lấy token

  OrderRepository({required this.authRepository});

  // Hàm helper lấy token (có thể copy từ BrandRepository)
  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  // Hàm tạo đơn hàng mới
  Future<OrderModel> createOrder({
    required List<Map<String, dynamic>>
        items, // Dữ liệu item theo format API yêu cầu
    String? note, // Ghi chú tùy chọn
    required int paymentMethod,
  }) async {
    String? token = await authRepository.getToken(); // Lấy token
    if (token == null) {
      throw Exception('Lỗi xác thực: Người dùng chưa đăng nhập.');
    }

    final url = Uri.parse('$baseUrl/api/orders');
    print('[OrderRepo] Calling Create Order API: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gửi token
        },
        body: jsonEncode({
          // Gửi đúng cấu trúc body mà backend mong đợi
          'items': items, // items là mảng [{product_id: ..., quantity: ...}]
          'note': note,
          'paymentMethod': paymentMethod,
        }),
      );

      print('[OrderRepo] Create Order Status Code: ${response.statusCode}');
      // print('[OrderRepo] Create Order Response Body: ${response.body}'); // Debug

      if (response.statusCode == 201) {
        // Backend trả về 201 Created khi thành công
        if (response.body.isEmpty) {
          throw Exception(
              'Đặt hàng thành công nhưng không nhận được dữ liệu đơn hàng.');
        }
        final body = jsonDecode(response.body);
        // Parse đơn hàng được trả về từ API
        // Đảm bảo Order.fromJson xử lý đúng cấu trúc JSON backend trả về
        return OrderModel.fromJson(body);
      } else {
        // Xử lý lỗi từ backend (ví dụ: hết hàng, lỗi server)
        String errorMessage =
            'Đặt hàng thất bại (Mã lỗi: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            errorMessage =
                body['message'] ?? errorMessage; // Ưu tiên message từ API
          } catch (e) {
            print(
                "[OrderRepo] Failed to decode error JSON body: ${response.body}");
            errorMessage =
                'Đặt hàng thất bại (Mã lỗi: ${response.statusCode}). Phản hồi không hợp lệ.';
          }
        }
        print("[OrderRepo] Create Order failed: $errorMessage"); // Debug
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[OrderRepo] Error calling Create Order API: $e');
      throw Exception(
          'Không thể tạo đơn hàng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Hàm lấy đơn hàng của tôi (luôn lấy tất cả từ API)
  Future<List<OrderModel>> getMyOrders({int? status}) async {
    // Tham số status ở đây chỉ để Bloc gọi, không dùng khi gọi API
    String? token = await authRepository.getToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Người dùng chưa đăng nhập.');
    }

    final url = Uri.parse('$baseUrl/api/orders/myorders');
    print(
        '[OrderRepo] Calling Get My Orders API (All Statuses - Filter on Client): $url');

    try {
      final response = await http.get(
        url, // Không thêm filter status vào URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[OrderRepo] Get My Orders Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<OrderModel> orders =
            body.map((dynamic item) => OrderModel.fromJson(item)).toList();
        return orders; // Trả về tất cả đơn hàng
      } else {
        String errorMessage =
            'Lấy lịch sử đơn hàng thất bại (Mã lỗi: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* Bỏ qua lỗi decode */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[OrderRepo] Error calling Get My Orders API: $e');
      throw Exception(
          'Không thể lấy lịch sử đơn hàng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Hàm lấy chi tiết đơn hàng theo ID
  Future<OrderModel> getOrderById(int orderId) async {
    String? token = await authRepository.getToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Người dùng chưa đăng nhập.');
    }
    final url = Uri.parse('$baseUrl/api/orders/$orderId');
    print('[OrderRepo] Calling Get Order By ID API: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('[OrderRepo] Get Order By ID Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Không nhận được dữ liệu chi tiết đơn hàng.');
        }
        // Chỉ cần parse trực tiếp vì JSON đã đúng cấu trúc
        final body =
            jsonDecode(utf8.decode(response.bodyBytes)); // Dùng utf8.decode
        return OrderModel.fromJson(body); // Gọi factory chuẩn
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy đơn hàng.');
      } else if (response.statusCode == 403) {
        throw Exception('Không có quyền xem đơn hàng này.');
      } else {
        // Xử lý lỗi chung...
        String errorMessage =
            'Lấy chi tiết đơn hàng thất bại (Mã lỗi: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[OrderRepo] Error calling Get Order By ID API: $e');
      throw Exception(
          'Không thể lấy chi tiết đơn hàng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  ////////////////////        ADMIN       ////////////////////
  // Lấy tất cả đơn hàng (Admin)
  Future<List<OrderModel>> getAllOrders() async {
    String? token = await _getToken();
    if (token == null) throw Exception('Admin authentication required');

    final url =
        Uri.parse('$baseUrl/api/orders'); // Endpoint GET /api/orders của admin
    print('[OrderRepo][Admin] Calling GET $url');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[OrderRepo][Admin] Get All Orders Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((dynamic item) => OrderModel.fromJson(item)).toList();
      } else {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['message'] ??
            'Failed to load all orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[OrderRepo][Admin] Error fetching all orders: $e');
      throw Exception(
          'Failed to load all orders: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Cập nhật trạng thái đơn hàng (Admin)
  Future<OrderModel> updateOrderStatus(int orderId, int newStatus) async {
    String? token = await _getToken();
    if (token == null) throw Exception('Admin authentication required');

    final url =
        Uri.parse('$baseUrl/api/orders/$orderId/status'); // Endpoint PUT status
    print('[OrderRepo][Admin] Calling PUT $url with status $newStatus');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // Quan trọng cho body
        },
        body: jsonEncode({'status': newStatus}), // Gửi status trong body
      );
      print('[OrderRepo][Admin] Update Status Code: ${response.statusCode}');
      print('[OrderRepo][Admin] Update Status Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['order'] != null && body['order'] is Map<String, dynamic>) {
          // Kiểm tra xem khóa 'order' có tồn tại và là một Map không
          return OrderModel.fromJson(
              body['order'] as Map<String, dynamic>); // Truy cập body['order']
        } else {
          throw Exception(
              'Không tìm thấy dữ liệu đơn hàng trong phản hồi từ API.');
        }
      } else {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['message'] ??
            'Failed to update order status. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('[OrderRepo][Admin] Error updating order status: $e');
      throw Exception(
          'Failed to update order status: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Xóa đơn hàng (Admin)
  Future<void> deleteOrder(int orderId) async {
    String? token = await _getToken();
    if (token == null) throw Exception('Admin authentication required');

    final url = Uri.parse('$baseUrl/api/orders/$orderId'); // Endpoint DELETE
    print('[OrderRepo][Admin] Calling DELETE $url');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[OrderRepo][Admin] Delete Order Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        // API trả về 200 khi thành công
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(body['message'] ??
            'Failed to delete order. Status: ${response.statusCode}');
      }
      // Xóa thành công, không cần trả về gì
    } catch (e) {
      print('[OrderRepo][Admin] Error deleting order: $e');
      throw Exception(
          'Failed to delete order: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
