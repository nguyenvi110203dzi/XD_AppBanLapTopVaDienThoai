import 'dart:convert';
import 'dart:io'; // Cần cho File nếu có upload ảnh (chưa cần cho các hàm ban đầu)

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Cần cho MediaType khi upload file
import 'package:image_picker/image_picker.dart'; // Cần cho XFile khi upload file

import '../config/app_constants.dart';
import '../models/user.dart'; // Import UserModel của bạn
import 'auth_repository.dart'; // Cần AuthRepository để lấy token

class UserRepository {
  final String baseUrl = AppConstants.baseUrl; // <<< Đảm bảo đúng baseUrl
  final AuthRepository _authRepository;

  UserRepository({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Hàm helper lấy token Admin
  Future<String?> _getAdminToken() async {
    // Giả định hàm này trong AuthRepository lấy token đã lưu
    // Cần đảm bảo token lấy được là của Admin khi gọi các hàm bên dưới
    return await _authRepository.getToken();
  }

  // --- CÁC HÀM API CHO ADMIN ---

  // 1. Lấy danh sách tất cả người dùng
  Future<List<UserModel>> getUsers() async {
    final token = await _getAdminToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Yêu cầu token Admin.');
    }

    final url = Uri.parse('$baseUrl/api/users');
    print('[UserRepo] Calling GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[UserRepo] Get Users Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        // Sử dụng UserModel.fromJson để parse từng user
        List<UserModel> users = body
            .map((dynamic item) => UserModel.fromJson(item))
            .where((user) => user.role != 1) // Lọc bỏ admin ra khỏi danh sách
            .toList();

        print('[UserRepo] Fetched ${users.length} users.');
        return users;
      } else {
        // Xử lý lỗi từ server
        String errorMessage =
            'Lỗi tải danh sách người dùng (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[UserRepo] Error fetching users: $e');
      throw Exception(
          'Không thể tải danh sách người dùng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // 2. Cập nhật thông tin người dùng (bao gồm cả role và ảnh)
  Future<UserModel> updateUser(int userId,
      {String? name,
      String? email, // Thường không nên cho Admin sửa email trực tiếp
      String? phone,
      int? role, // Cho phép cập nhật role (0=user, 1=admin)
      XFile? avatarFile // File ảnh mới nếu có
      }) async {
    final token = await _getAdminToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Yêu cầu token Admin.');
    }

    final url = Uri.parse('$baseUrl/api/users/$userId');
    print('[UserRepo] Calling PUT $url');
    var request = http.MultipartRequest('PUT', url);

    // Headers
    request.headers['Authorization'] = 'Bearer $token';

    // Fields (Chỉ thêm field nếu giá trị không null)
    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email; // Cẩn thận khi cho sửa
    if (phone != null) request.fields['phone'] = phone;
    if (role != null)
      request.fields['role'] = role.toString(); // Gửi role dưới dạng String

    // File Avatar (nếu có)
    if (avatarFile != null) {
      try {
        File file = File(avatarFile.path);
        String fileName = file.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();
        MediaType? contentType;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        }
        // Key là 'avatar', khớp với upload.single('avatar') trong userRoutes.js
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          file.path,
          contentType: contentType,
          filename: fileName,
        ));
        print(
            '[UserRepo] Added avatar image to update request for user $userId');
      } catch (e) {
        print('[UserRepo] Error processing avatar file for update: $e');
        // Xem xét có nên throw lỗi hay chỉ bỏ qua ảnh
      }
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('[UserRepo] Update User $userId Status: ${response.statusCode}');
      print('[UserRepo] Update User $userId Response: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Cập nhật thành công nhưng không nhận được dữ liệu.');
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        // API trả về user đã cập nhật (không có password)
        return UserModel.fromJson(body);
      } else {
        String errorMessage =
            'Lỗi cập nhật người dùng (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[UserRepo] Error updating user $userId: $e');
      throw Exception(
          'Không thể cập nhật người dùng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // 3. Xóa người dùng
  Future<void> deleteUser(int userId) async {
    final token = await _getAdminToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Yêu cầu token Admin.');
    }

    final url = Uri.parse('$baseUrl/api/users/$userId');
    print('[UserRepo] Calling DELETE $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print('[UserRepo] Delete User $userId Status: ${response.statusCode}');

      // API trả về 200 OK và { message: 'User removed' } khi thành công
      if (response.statusCode != 200) {
        String errorMessage =
            'Lỗi xóa người dùng (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
            // Kiểm tra các lỗi cụ thể nếu backend trả về, ví dụ không thể xóa admin gốc
          } catch (e) {/* ignore */}
        }
        // TODO: Kiểm tra các mã lỗi cụ thể nếu cần (ví dụ: 404 Not Found)
        if (response.statusCode == 404) {
          throw Exception('Không tìm thấy người dùng để xóa.');
        }
        throw Exception(errorMessage);
      }
      // Xóa thành công
      print('[UserRepo] User $userId deleted successfully.');
    } catch (e) {
      print('[UserRepo] Error deleting user $userId: $e');
      throw Exception(
          'Không thể xóa người dùng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // 4. Lấy chi tiết người dùng (Ít dùng trong màn hình list, nhưng có thể cần)
  Future<UserModel> getUserById(int userId) async {
    final token = await _getAdminToken();
    if (token == null) {
      throw Exception('Lỗi xác thực: Yêu cầu token Admin.');
    }

    final url = Uri.parse('$baseUrl/api/users/$userId');
    print('[UserRepo] Calling GET $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          '[UserRepo] Get User By ID $userId Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return UserModel.fromJson(body);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy người dùng.');
      } else {
        String errorMessage =
            'Lỗi tải chi tiết người dùng (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[UserRepo] Error fetching user by ID $userId: $e');
      throw Exception(
          'Không thể tải chi tiết người dùng: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
