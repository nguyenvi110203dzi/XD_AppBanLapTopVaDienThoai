import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_constants.dart';
import '../models/banner.dart';
import 'auth_repository.dart'; // Đảm bảo đúng tên file model Banner

class BannerRepository {
  final String baseUrl = AppConstants.baseUrl;
  final AuthRepository authRepository;

  BannerRepository({required this.authRepository});

  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  Future<List<BannerModel>> getBanners() async {
    final response = await http.get(Uri.parse('$baseUrl/api/banners'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<BannerModel> banners =
          body.map((dynamic item) => BannerModel.fromJson(item)).toList();
      return banners;
    } else {
      throw Exception('Failed to load banners');
    }
  }

  ////////////////           ADMIN                //////////////
  Future<List<BannerModel>> getAdminBanners() async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    // Gọi endpoint admin mới tạo ở backend
    final url = Uri.parse('$baseUrl/api/banners/admin');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'}, // Cần token admin
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => BannerModel.fromJson(item)).toList();
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to load admin banners. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error getting admin banners: $e");
      throw Exception('Failed to load admin banners: ${e.toString()}');
    }
  }

  // Tạo banner mới
  Future<BannerModel> createBanner(
      {String? name, required int status, File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/banners'); // Endpoint POST banner
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Thêm các field (name là tùy chọn)
    if (name != null && name.isNotEmpty) {
      request.fields['name'] = name;
    }
    request.fields['status'] = status.toString(); // Gửi status dạng string

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        List<int> fileBytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Field name cho file
          fileBytes,
          filename: fileName,
          contentType: MediaType('image', fileName.split('.').last),
        );
        request.files.add(multipartFile);
      } catch (e) {
        print("Error adding image to request: $e");
      }
    } else {
      // Nếu không có ảnh thì không thể tạo banner (Backend yêu cầu ảnh?)
      // Cần xem lại logic backend, ở đây giả sử có thể tạo banner không ảnh
      // Hoặc ném lỗi nếu ảnh là bắt buộc
      throw Exception('Ảnh banner là bắt buộc.');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Created
        final body = jsonDecode(response.body);
        return BannerModel.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to create banner. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error creating banner: $e");
      throw Exception(
          'Failed to create banner: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Cập nhật banner
  Future<BannerModel> updateBanner(
      {required int id,
      String? name,
      required int status,
      File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/banners/$id'); // Endpoint PUT banner
    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    // Thêm các field (name là tùy chọn)
    if (name != null && name.isNotEmpty) {
      request.fields['name'] = name;
    } else {
      // Nếu muốn xóa tên cũ khi cập nhật mà không truyền tên mới (Backend xử lý?)
      // request.fields['name'] = ''; // Hoặc không gửi field 'name'
    }
    request.fields['status'] = status.toString();

    if (imageFile != null) {
      // Chỉ gửi ảnh nếu có ảnh mới được chọn
      try {
        String fileName = imageFile.path.split('/').last;
        List<int> fileBytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Field name cho file
          fileBytes,
          filename: fileName,
          contentType: MediaType('image', fileName.split('.').last),
        );
        request.files.add(multipartFile);
      } catch (e) {
        print("Error adding image to request: $e");
      }
    }
    // Nếu không có imageFile mới, backend sẽ giữ lại ảnh cũ

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // OK
        final body = jsonDecode(response.body);
        return BannerModel.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to update banner. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error updating banner: $e");
      throw Exception(
          'Failed to update banner: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Xóa banner
  Future<void> deleteBanner(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/banners/$id'); // Endpoint DELETE banner
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(
            'Failed to delete banner. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error deleting banner: $e");
      throw Exception(
          'Failed to delete banner: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
