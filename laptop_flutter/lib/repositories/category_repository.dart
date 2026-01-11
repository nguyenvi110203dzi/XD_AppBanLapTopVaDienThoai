import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_constants.dart';
import '../models/category.dart';
import 'auth_repository.dart'; // Import model Category

class CategoryRepository {
  final String baseUrl = AppConstants.baseUrl; // Thay base URL
  final AuthRepository authRepository; // <-- Thêm biến thành viên

  CategoryRepository({required this.authRepository});

  Future<String?> _getToken() async {
    return await authRepository.getToken();
  }

  Future<List<Category>> getCategories() async {
    final url = Uri.parse('$baseUrl/api/categories');
    print('Calling API: $url');
    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        // Sắp xếp theo tên trước khi trả về nếu muốn
        List<Category> categories = body
            .map((dynamic item) => Category.fromJson(item))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        return categories;
      } else {
        throw Exception(
            'Failed to load categories. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API $url: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  ///////////////////          ADMIN        ///////////////////
  // Tạo danh mục mới
  Future<Category> createCategory(
      {required String name, File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/categories'); // Endpoint categories
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        List<int> fileBytes = await imageFile.readAsBytes();
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Field name cho file trong backend
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

      if (response.statusCode == 201) {
        // Created
        final body = jsonDecode(response.body);
        return Category.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to create category. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error creating category: $e");
      throw Exception(
          'Failed to create category: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Cập nhật danh mục
  Future<Category> updateCategory(
      {required int id, required String name, File? imageFile}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/categories/$id'); // Endpoint categories
    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;

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
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // OK
        final body = jsonDecode(response.body);
        return Category.fromJson(body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Failed to update category. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error updating category: $e");
      throw Exception(
          'Failed to update category: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Xóa danh mục
  Future<void> deleteCategory(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');

    final url = Uri.parse('$baseUrl/api/categories/$id'); // Endpoint categories
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        // Lỗi không thể xóa do có sản phẩm
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ??
            'Cannot delete category with associated products.');
      } else {
        throw Exception(
            'Failed to delete category. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error deleting category: $e");
      throw Exception(
          'Failed to delete category: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
