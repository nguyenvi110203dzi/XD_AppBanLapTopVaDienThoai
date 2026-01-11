import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http; // Hoặc dio
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_constants.dart';
import '../models/cameramanhinh.dart';
import '../models/cauhinhbonho.dart';
import '../models/pinvasac.dart';
import '../models/product.dart';
import 'auth_repository.dart';

class ProductRepository {
  final String baseUrl = AppConstants.baseUrl; // Thay bằng base URL API của bạn
  final AuthRepository _authRepository;

  // Constructor nhận AuthRepository
  ProductRepository({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // Hàm helper lấy token
  Future<String?> _getToken() async {
    return await _authRepository.getToken();
  }

  Future<List<ProductModel>> getNewProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/new'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ProductModel> products =
          body.map((dynamic item) => ProductModel.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load new products');
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ProductModel> products =
          body.map((dynamic item) => ProductModel.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load all products');
    }
  }

  Future<List<ProductModel>> getCategory1Products() async {
    final url = Uri.parse('$baseUrl/api/products/category1');
    print('[ProductRepo] Calling GET $url');
    try {
      final response = await http.get(url);
      print(
          '[ProductRepo] Get Category 1 Products Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Decode thành dynamic trước để kiểm tra kiểu
        final dynamic decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // Kiểm tra xem dữ liệu decode ra là List hay Map
        if (decodedData is List) {
          // Nếu là List, xử lý như bình thường
          List<dynamic> body = decodedData;
          List<ProductModel> products =
              body.map((dynamic item) => ProductModel.fromJson(item)).toList();
          print('[ProductRepo] Parsed ${products.length} products from List.');
          return products;
        } else if (decodedData is Map<String, dynamic>) {
          // Nếu là Map, cố gắng tìm key chứa List (ví dụ: 'data', 'products')
          // *** THAY 'data' BẰNG KEY THỰC TẾ NẾU BACKEND TRẢ VỀ KHÁC ***
          final String listKey =
              'data'; // Hoặc 'products', 'items',... tùy backend
          if (decodedData.containsKey(listKey) &&
              decodedData[listKey] is List) {
            print(
                '[ProductRepo] Response was a Map, extracting list from key "$listKey".');
            List<dynamic> body = decodedData[listKey];
            List<ProductModel> products = body
                .map((dynamic item) => ProductModel.fromJson(item))
                .toList();
            return products;
          } else {
            // Nếu là Map nhưng không chứa key mong đợi hoặc key đó không phải List
            print(
                '[ProductRepo] Error: Response is a Map but does not contain a valid list under key "$listKey". Response: $decodedData');
            throw Exception(
                'Invalid response format from API: Expected a List or a Map containing a List under key "$listKey".');
          }
        } else {
          // Nếu không phải List cũng không phải Map
          print(
              '[ProductRepo] Error: Response format is neither List nor Map. Response: $decodedData');
          throw Exception(
              'Invalid response format from API: Unexpected data type.');
        }
      } else if (response.statusCode == 404) {
        print('[ProductRepo] No products found for category 1 (404).');
        return []; // Trả về mảng rỗng nếu 404
      } else {
        // Các lỗi HTTP khác
        throw Exception(
            'Failed to load category 1 products. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Lỗi mạng hoặc lỗi parse JSON
      print('[ProductRepo] Error in getCategory1Products: $e');
      // Ném lại lỗi để BLoC xử lý
      throw Exception(
          'Failed to load category 1 products: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Thêm hàm tìm kiếm (sẽ cần API tương ứng)
  Future<List<ProductModel>> searchProducts(String query) async {
    // Giả sử API tìm kiếm là /api/products/search?q={query}
    final response =
        await http.get(Uri.parse('$baseUrl/api/products/search?q=$query'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<ProductModel> products =
          body.map((dynamic item) => ProductModel.fromJson(item)).toList();
      return products;
    } else if (response.statusCode == 404) {
      return []; // Không tìm thấy sản phẩm
    } else {
      throw Exception('Failed to search products');
    }
  }

  // Lấy TẤT CẢ sản phẩm theo brandId (Workaround do backend chưa có pagination)
  Future<List<ProductModel>> getProductsByBrand(int brandId) async {
    final url = Uri.parse('$baseUrl/api/products/brand/$brandId');
    print('Calling API: $url');
    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ProductModel> products =
            body.map((dynamic item) => ProductModel.fromJson(item)).toList();
        return products;
      } else if (response.statusCode == 404) {
        return []; // Không tìm thấy sản phẩm nào
      } else {
        throw Exception(
            'Failed to load products by brand. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API $url: $e');
      throw Exception('Failed to load products by brand: $e');
    }
  }

  // Lấy TẤT CẢ sản phẩm theo categoryId
  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    if (categoryId == 1) {
      return getCategory1Products();
    }
    final url = Uri.parse('$baseUrl/api/products/category/$categoryId');
    print('Calling API: $url');
    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ProductModel> products =
            body.map((dynamic item) => ProductModel.fromJson(item)).toList();
        return products;
      } else if (response.statusCode == 404) {
        return []; // Không tìm thấy sản phẩm nào
      } else {
        throw Exception(
            'Failed to load products by category. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API $url: $e');
      throw Exception('Failed to load products by category: $e');
    }
  }

  Future<ProductModel> getProductById(int productId) async {
    print('[ProductRepo] Getting product detail for ID: $productId');
    try {
      // Bước 1: Gọi API /category1 để lấy danh sách đầy đủ thông tin
      // (Giả định sản phẩm cần xem chi tiết thuộc category 1)
      // Nếu sản phẩm có thể thuộc category khác và cần chi tiết,
      // bạn cần logic phức tạp hơn hoặc sửa backend API /api/products/:id
      final category1Products = await getCategory1Products();

      // Bước 2: Tìm sản phẩm trong danh sách trả về bằng ID
      // Sử dụng firstWhereOrNull từ package:collection/collection.dart
      final product = category1Products.firstWhereOrNull(
        (p) => p.id == productId,
      );

      // Bước 3: Kiểm tra kết quả
      if (product != null) {
        print('[ProductRepo] Found product ID $productId in category 1 list.');
        return product; // Trả về sản phẩm tìm thấy
      } else {
        // Nếu không tìm thấy trong category 1, có thể thử gọi API gốc /api/products/:id
        // --- Tùy chọn: Thử gọi API gốc nếu không thấy trong category 1 ---
        print(
            '[ProductRepo] Product ID $productId not found in category 1 list. Trying direct API call...');
        final directUrl = Uri.parse('$baseUrl/api/products/$productId');
        final directResponse = await http.get(directUrl);
        print(
            '[ProductRepo] Direct Get Product $productId Status: ${directResponse.statusCode}');
        if (directResponse.statusCode == 200) {
          Map<String, dynamic> body =
              jsonDecode(utf8.decode(directResponse.bodyBytes));
          // Lưu ý: Dữ liệu này có thể thiếu chi tiết
          return ProductModel.fromJson(body);
        } else if (directResponse.statusCode == 404) {
          throw Exception('Product with ID $productId not found.');
        } else {
          throw Exception(
              'Failed to load product details directly. Status: ${directResponse.statusCode}');
        }
      }
    } catch (e) {
      print('[ProductRepo] Error getting product $productId: $e');
      // Ném lại lỗi để BLoC xử lý và hiển thị cho người dùng
      throw Exception(
          'Failed to load product details for ID $productId: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Thêm hàm tìm kiếm sản phẩm theo tên
  Future<List<ProductModel>> searchProductsByName(String searchTerm) async {
    // Encode searchTerm để xử lý các ký tự đặc biệt trong URL
    final encodedSearchTerm = Uri.encodeComponent(searchTerm);
    final url =
        Uri.parse('$baseUrl/api/products/search?name=$encodedSearchTerm');
    print('Calling API: $url');
    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<ProductModel> products =
            body.map((dynamic item) => ProductModel.fromJson(item)).toList();
        return products;
      } else if (response.statusCode == 404) {
        // API có thể không trả về 404 nếu tìm không thấy, mà trả về mảng rỗng [] với status 200
        return []; // Trả về list rỗng nếu không tìm thấy
      } else if (response.statusCode == 400) {
        // Lỗi do thiếu search term (dù frontend nên chặn trước)
        throw Exception('Search term is required');
      } else {
        throw Exception(
            'Failed to search products. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling API $url: $e');
      throw Exception('Failed to search products: $e');
    }
  }

  /////////////////        ADMIN           /////////////////
  // Hàm helper chung để gửi request PUT/POST JSON
  Future<Map<String, dynamic>> _sendJsonRequest(
      String method, String endpoint, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực: Yêu cầu token Admin.');

    final url = Uri.parse('$baseUrl$endpoint');
    print('[ProductRepo] Calling $method $url');

    http.Response response;
    try {
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      };
      final encodedBody = jsonEncode(body);
      print('[ProductRepo] Request Body: $encodedBody');

      if (method.toUpperCase() == 'PUT') {
        response = await http.put(url, headers: headers, body: encodedBody);
      } else if (method.toUpperCase() == 'POST') {
        response = await http.post(url, headers: headers, body: encodedBody);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      print('[ProductRepo] Response Status: ${response.statusCode}');
      print('[ProductRepo] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK (Update), 201 Created (Create)
        if (response.body.isEmpty) {
          // Có thể trả về {} nếu thành công mà không có body
          return {};
        }
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        String errorMessage =
            'Lỗi không xác định (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        if (response.statusCode == 404) {
          errorMessage = 'Không tìm thấy tài nguyên liên quan.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Dữ liệu gửi lên không hợp lệ: $errorMessage';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ProductRepo] Error sending $method request to $endpoint: $e');
      throw Exception(
          'Lỗi kết nối hoặc xử lý: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // --- Cập nhật/Tạo CauhinhBonho ---
  Future<CauhinhBonho> saveCauHinhBonho(
      int productId, CauhinhBonho data) async {
    // Giả sử API dùng PUT để cập nhật hoặc tạo nếu chưa có
    final endpoint = '/api/products/$productId/cauhinh';
    // Backend cần trả về object CauhinhBonho đã được lưu
    final responseBody = await _sendJsonRequest('PUT', endpoint, data.toJson());
    // Parse lại từ response để đảm bảo có ID đúng (nếu là tạo mới)
    return CauhinhBonho.fromJson(responseBody);
  }

  // --- Cập nhật/Tạo CameraManhinh ---
  Future<CameraManhinh> saveCameraManhinh(
      int productId, CameraManhinh data) async {
    final endpoint = '/api/products/$productId/camera';
    final responseBody = await _sendJsonRequest('PUT', endpoint, data.toJson());
    return CameraManhinh.fromJson(responseBody);
  }

  // --- Cập nhật/Tạo PinSac ---
  Future<PinSac> savePinSac(int productId, PinSac data) async {
    final endpoint = '/api/products/$productId/pinsac';
    final responseBody = await _sendJsonRequest('PUT', endpoint, data.toJson());
    return PinSac.fromJson(responseBody);
  }

  // Tạo sản phẩm mới
  Future<ProductModel> createProduct({
    required String name,
    required int price,
    int? oldprice, // Giá cũ có thể null
    required String description,
    required String specification,
    required int quantity,
    required int brandId,
    required int categoryId,
    XFile? imageFile, // Ảnh có thể null
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực: Yêu cầu token Admin.');

    final url = Uri.parse('$baseUrl/api/products');
    print('[ProductRepo] Calling POST $url');
    var request = http.MultipartRequest('POST', url);

    // Headers
    request.headers['Authorization'] = 'Bearer $token';

    // Fields - Chuyển các giá trị số thành String
    request.fields['name'] = name;
    request.fields['price'] = price.toString();
    if (oldprice != null) request.fields['oldprice'] = oldprice.toString();
    request.fields['description'] = description;
    request.fields['specification'] = specification;
    request.fields['quantity'] = quantity.toString();
    request.fields['brand_id'] = brandId.toString();
    request.fields['category_id'] = categoryId.toString();

    // File Image (nếu có)
    if (imageFile != null) {
      try {
        File file = File(imageFile.path);
        String fileName = file.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();
        MediaType? contentType;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        }
        // Key là 'image', khớp với upload.single('image') trong productRoutes.js
        request.files.add(await http.MultipartFile.fromPath(
          'image', // <<< Key field cho file ảnh
          file.path,
          contentType: contentType,
          filename: fileName,
        ));
        print('[ProductRepo] Added image to create product request');
      } catch (e) {
        print(
            '[ProductRepo] Error processing image file for create product: $e');
        // Có thể throw lỗi ở đây nếu ảnh là bắt buộc hoặc xử lý tiếp tùy logic
      }
    }

    // Gửi request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print('[ProductRepo] Create Product Status: ${response.statusCode}');
      print('[ProductRepo] Create Product Response: ${response.body}');

      // Backend trả về 201 Created khi thành công
      if (response.statusCode == 201) {
        if (response.body.isEmpty) {
          throw Exception(
              'Thêm sản phẩm thành công nhưng không nhận được dữ liệu.');
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        // Parse sản phẩm được trả về (có thể không kèm brand/category, tùy backend)
        // Giả sử API trả về đủ thông tin để parse bằng ProductModel.fromJson
        return ProductModel.fromJson(body);
      } else {
        // Xử lý lỗi từ server
        String errorMessage =
            'Lỗi thêm sản phẩm (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ProductRepo] Error creating product: $e');
      throw Exception(
          'Không thể thêm sản phẩm: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Cập nhật sản phẩm
  Future<ProductModel> updateProduct(
    int productId, {
    String? name, // Các trường đều là optional khi update
    int? price,
    int? oldprice,
    String? description,
    String? specification,
    int? quantity,
    int? brandId,
    int? categoryId,
    XFile? imageFile, // Ảnh mới (null nếu không đổi)
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực: Yêu cầu token Admin.');

    final url = Uri.parse('$baseUrl/api/products/$productId');
    print('[ProductRepo] Calling PUT $url');
    var request = http.MultipartRequest('PUT', url);

    // Headers
    request.headers['Authorization'] = 'Bearer $token';

    // Fields (Chỉ thêm field nếu giá trị được cung cấp)
    if (name != null) request.fields['name'] = name;
    if (price != null) request.fields['price'] = price.toString();
    if (oldprice != null)
      request.fields['oldprice'] =
          oldprice.toString(); // Có thể cần logic để xóa giá cũ nếu muốn
    if (description != null) request.fields['description'] = description;
    if (specification != null) request.fields['specification'] = specification;
    if (quantity != null) request.fields['quantity'] = quantity.toString();
    if (brandId != null) request.fields['brand_id'] = brandId.toString();
    if (categoryId != null)
      request.fields['category_id'] = categoryId.toString();

    // File Image (nếu có)
    if (imageFile != null) {
      try {
        File file = File(imageFile.path);
        String fileName = file.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();
        MediaType? contentType;
        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        }
        request.files.add(await http.MultipartFile.fromPath(
          'image', // Key field
          file.path,
          contentType: contentType,
          filename: fileName,
        ));
        print('[ProductRepo] Added image to update product $productId request');
      } catch (e) {
        print(
            '[ProductRepo] Error processing image file for update product: $e');
      }
    }

    // Gửi request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      print(
          '[ProductRepo] Update Product $productId Status: ${response.statusCode}');
      print(
          '[ProductRepo] Update Product $productId Response: ${response.body}');

      // Backend trả về 200 OK khi thành công
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception(
              'Cập nhật sản phẩm thành công nhưng không nhận được dữ liệu.');
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        // Parse sản phẩm đã cập nhật
        return ProductModel.fromJson(body);
      } else {
        // Xử lý lỗi từ server
        String errorMessage =
            'Lỗi cập nhật sản phẩm (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        if (response.statusCode == 404) {
          throw Exception('Không tìm thấy sản phẩm để cập nhật.');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[ProductRepo] Error updating product $productId: $e');
      throw Exception(
          'Không thể cập nhật sản phẩm: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // Xóa sản phẩm
  Future<void> deleteProduct(int productId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Lỗi xác thực: Yêu cầu token Admin.');

    final url = Uri.parse('$baseUrl/api/products/$productId');
    print('[ProductRepo] Calling DELETE $url');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
          '[ProductRepo] Delete Product $productId Status: ${response.statusCode}');

      // API trả về 200 OK và { message: 'Product removed' } khi thành công
      if (response.statusCode != 200) {
        String errorMessage = 'Lỗi xóa sản phẩm (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = body['message'] ?? errorMessage;
            // Có thể kiểm tra lỗi ràng buộc khóa ngoại nếu backend trả về
          } catch (e) {/* ignore */}
        }
        if (response.statusCode == 404) {
          throw Exception('Không tìm thấy sản phẩm để xóa.');
        }
        throw Exception(errorMessage);
      }
      // Xóa thành công
      print('[ProductRepo] Product $productId deleted successfully.');
    } catch (e) {
      print('[ProductRepo] Error deleting product $productId: $e');
      throw Exception(
          'Không thể xóa sản phẩm: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
