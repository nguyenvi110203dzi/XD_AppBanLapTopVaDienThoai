import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_constants.dart';
import '../models/user.dart';

//127.0.0.1 web
// 192.168.1.177
// 10.0.0.1 dt ao
class AuthRepository {
  final String baseUrl = AppConstants.baseUrl;
  final _storage = const FlutterSecureStorage(); // Để lưu token
  final String _tokenKey = 'user_token'; // Key để lưu token

  // --- Token Handling ---
  Future<void> persistToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    String? token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // --- API Calls ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // API trả về { user: {...}, token: '...' }
      if (body['token'] != null && body['user'] != null) {
        await persistToken(body['token']); // Lưu token ngay
        return body; // Trả về cả user và token
      } else {
        throw Exception('Invalid response format from login API');
      }
    } else {
      // Ném lỗi dựa trên response từ API (ví dụ: sai mật khẩu)
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone ?? '',
      }),
    );

    if (response.statusCode == 201) {
      // Status 201 Created
      final body = jsonDecode(response.body);
      if (body['token'] != null && body['user'] != null) {
        await persistToken(body['token']);
        return body;
      } else {
        throw Exception('Invalid response format from register API');
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registration failed');
    }
  }

  Future<UserModel> getUserProfile() async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated: No token found');
    }

    final url = Uri.parse('$baseUrl/api/auth/profile');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Gửi token
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return UserModel.fromJson(body); // Giả sử API trả về đúng object User
    } else if (response.statusCode == 401 || response.statusCode == 404) {
      await deleteToken(); // Xóa token cũ nếu không hợp lệ hoặc user không tồn tại
      throw Exception('Unauthorized or User not found');
    } else {
      throw Exception(
          'Failed to load user profile. Status: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    await deleteToken(); // Chỉ cần xóa token ở client là đủ cho stateless API
  }

  // Hàm cập nhật profile
  Future<UserModel> updateUserProfile({
    String? name,
    String? phone,
    String? avatarImagePath,
  }) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated: No token found');
    }

    final url = Uri.parse('$baseUrl/api/auth/profile');
    // Tạo request dạng multipart
    var request = http.MultipartRequest('PUT', url);

    // Thêm headers (Quan trọng: Authorization và Content-Type sẽ được thư viện http tự đặt đúng khi có file)
    request.headers['Authorization'] = 'Bearer $token';
    // Không cần đặt Content-Type: multipart/form-data thủ công ở đây

    // Thêm các trường dữ liệu text nếu chúng được cung cấp
    if (name != null) request.fields['name'] = name;
    if (phone != null) request.fields['phone'] = phone;

    // Thêm file ảnh nếu có đường dẫn
    if (avatarImagePath != null && avatarImagePath.isNotEmpty) {
      File imageFile = File(avatarImagePath);
      if (await imageFile.exists()) {
        String fileName = imageFile.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();
        MediaType? contentType;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        }
        // Thêm các kiểu khác nếu cần

        try {
          print(
              '[AuthRepo] Reading file bytes from: ${imageFile.path}'); // Debug
          // Đọc nội dung file thành List<int> (bytes)
          List<int> fileBytes = await imageFile.readAsBytes();

          // Tạo MultipartFile từ bytes thay vì từ path
          var multipartFile = http.MultipartFile.fromBytes(
            'avatar', // Tên field quan trọng, phải khớp với backend multer: upload.single('avatar')
            fileBytes, // << Truyền nội dung bytes vào đây
            filename: fileName, // Giữ lại tên file gốc
            contentType: contentType, // Giữ lại kiểu file
          );

          // Thêm file vào request
          request.files.add(multipartFile);
          print(
              '[AuthRepo] Added avatar file as bytes: $fileName, ContentType: $contentType'); // Debug
        } catch (e) {
          print(
              '[AuthRepo] Error reading or creating multipart file from bytes: $e');
          // Có thể throw lỗi ở đây hoặc bỏ qua việc upload ảnh nếu đọc file lỗi
          // throw Exception("Không thể đọc file ảnh: $e");
        }
      } else {
        print(
            '[AuthRepo] Warning: Avatar image file not found at $avatarImagePath');
      }
    }
    try {
      // Gửi request
      var streamedResponse = await request.send();
      // Đọc response
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        // Thành công, API trả về object User đã cập nhật
        if (response.body.isEmpty) {
          throw Exception(
              'Update successful but received empty response body.');
        }
        final body = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(body);
        return updatedUser; // Trả về User mới
      } else {
        // Xử lý lỗi an toàn
        String errorMessage =
            'Cập nhật thất bại (Mã lỗi: ${response.statusCode})';
        String responseBody = response.body; // Lưu lại body để log
        print(
            "[AuthRepo] Update Profile Error - Status: ${response.statusCode}, Body: $responseBody"); // <<< LOG CHI TIẾT
        if (responseBody.isNotEmpty) {
          try {
            final body = jsonDecode(responseBody);
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {
            print("[AuthRepo] Failed to decode error JSON body: $responseBody");
            errorMessage =
                'Cập nhật thất bại (Mã lỗi: ${response.statusCode}). Phản hồi không hợp lệ.';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print(
          "[AuthRepo] Exception during profile update: $e"); // <<< LOG EXCEPTION
      throw Exception(
          'Không thể cập nhật hồ sơ: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
