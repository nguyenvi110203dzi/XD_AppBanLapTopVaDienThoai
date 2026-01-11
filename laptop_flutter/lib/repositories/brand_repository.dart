import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_constants.dart';
import '../models/brand.dart';
import 'auth_repository.dart'; // Đảm bảo import đúng model Brand

class BrandRepository {
  final String baseUrl = AppConstants.baseUrl; // Thay base URL
  final AuthRepository authRepository;

  BrandRepository({required this.authRepository});

  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  Future<List<Brand>> getBrands() async {
    final url = Uri.parse('$baseUrl/api/brands');
    print('Calling API: $url');
    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');
      // print('API Response Body:\n${response.body}'); // Bỏ comment nếu cần debug

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Brand> brands =
            body.map((dynamic item) => Brand.fromJson(item)).toList();
        return brands;
      } else {
        throw Exception(
            'Failed to load brands. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API $url: $e');
      throw Exception('Failed to load brands: $e');
    }
  }

  // Tạo thương hiệu mới
  Future<Brand> createBrand({required String name, File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/brands');
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        List<int> fileBytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Phải khớp với tên field trong backend (upload.single('image'))
          fileBytes,
          filename: fileName,
          contentType: MediaType(
              'image', fileName.split('.').last), // Tự suy luận ContentType
        );
        request.files.add(multipartFile);
      } catch (e) {
        print("Error adding image to request: $e");
        // Có thể throw lỗi hoặc bỏ qua ảnh nếu đọc file lỗi
        // throw Exception("Không thể xử lý file ảnh: $e");
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Created
        final body = jsonDecode(response.body);
        return Brand.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to create brand. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error creating brand: $e");
      throw Exception(
          'Failed to create brand: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Cập nhật thương hiệu
  Future<Brand> updateBrand(
      {required int id, required String name, File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/brands/$id');
    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        List<int> fileBytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Phải khớp với tên field trong backend (upload.single('image'))
          fileBytes,
          filename: fileName,
          contentType: MediaType('image', fileName.split('.').last),
        );
        request.files.add(multipartFile);
      } catch (e) {
        print("Error adding image to request: $e");
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // OK
        final body = jsonDecode(response.body);
        return Brand.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to update brand. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error updating brand: $e");
      throw Exception(
          'Failed to update brand: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Xóa thương hiệu
  Future<void> deleteBrand(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/brands/$id');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Thành công
        return;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        throw Exception(
            body['message'] ?? 'Cannot delete brand with associated products.');
      } else {
        // Thất bại
        throw Exception(
            'Failed to delete brand. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error deleting brand: $e");
      throw Exception(
          'Failed to delete brand: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
