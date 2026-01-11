import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_constants.dart';
import '../models/cameramanhinh.dart';
// Import models và repo khác nếu cần
import '../models/cauhinhbonho.dart';
import '../models/pinvasac.dart';
import 'auth_repository.dart'; // Để lấy token

class SpecRepository {
  final String baseUrl =
      AppConstants.baseUrl + "/api/admin"; // Base URL cho API admin spec
  final AuthRepository _authRepository;

  SpecRepository({required AuthRepository authRepository})
      : _authRepository = authRepository;

  // --- Helper lấy Token ---
  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null) {
      throw Exception('Authentication Error: Admin token is required.');
    }
    return token;
  }

  // --- Helper gửi Request và xử lý Response ---
  Future<dynamic> _sendRequest(String method, String endpoint,
      {dynamic body}) async {
    final token = await _getToken(); // Lấy token cho mỗi request
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    http.Response response;

    print('[SpecRepo] Calling $method $url');
    if (body != null) print('[SpecRepo] Request Body: ${jsonEncode(body)}');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response =
              await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response =
              await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('[SpecRepo] Response Status: ${response.statusCode}');
      // In body nếu không phải 204 No Content
      if (response.statusCode != 204) {
        print('[SpecRepo] Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      // Xử lý response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Thành công (200 OK, 201 Created, 204 No Content)
        if (response.bodyBytes.isEmpty) {
          return null; // Trả về null nếu body rỗng (ví dụ: DELETE thành công)
        }
        return jsonDecode(utf8.decode(response.bodyBytes)); // Decode UTF8
      } else {
        // Xử lý lỗi từ server
        String errorMessage =
            'Lỗi không xác định (Code: ${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
            errorMessage = errorBody['message'] ?? errorMessage;
          } catch (e) {/* ignore */}
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = 'Lỗi xác thực hoặc phân quyền.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Không tìm thấy tài nguyên.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Dữ liệu không hợp lệ: $errorMessage';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('[SpecRepo] Error sending $method request to $endpoint: $e');
      // Ném lại lỗi để BLoC xử lý
      throw Exception(
          'Lỗi kết nối hoặc xử lý: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // --- CRUD cho CauHinhBonho ---

  Future<List<CauhinhBonho>> getAllCauHinh() async {
    final responseData = await _sendRequest('GET', '/spec/cauhinh');
    if (responseData is List) {
      return responseData.map((item) => CauhinhBonho.fromJson(item)).toList();
    }
    throw Exception('Invalid response format for getAllCauHinh');
  }

  Future<CauhinhBonho> createCauHinh(CauhinhBonho data) async {
    // Đảm bảo gửi id_product trong body
    final requestBody = data.toJson();
    if (requestBody['id_product'] == null) {
      throw Exception('Missing id_product when creating CauHinhBonho');
    }
    final responseData =
        await _sendRequest('POST', '/spec/cauhinh', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return CauhinhBonho.fromJson(responseData);
    }
    throw Exception('Invalid response format for createCauHinh');
  }

  Future<CauhinhBonho> updateCauHinh(int id, CauhinhBonho data) async {
    // Đảm bảo gửi id_product trong body
    final requestBody = data.toJson();
    if (requestBody['id_product'] == null) {
      // Cho phép bỏ gán bằng cách gửi id_product: null
      // Nếu không cho phép bỏ gán thì throw Exception ở đây
      // throw Exception('Missing id_product when updating CauHinhBonho');
    }
    final responseData =
        await _sendRequest('PUT', '/spec/cauhinh/$id', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return CauhinhBonho.fromJson(responseData);
    }
    throw Exception('Invalid response format for updateCauHinh');
  }

  Future<void> deleteCauHinh(int id) async {
    await _sendRequest('DELETE', '/spec/cauhinh/$id');
    // Không cần trả về gì nếu thành công
  }

  // --- CRUD cho CameraManhinh ---

  Future<List<CameraManhinh>> getAllCameraManhinh() async {
    final responseData = await _sendRequest('GET', '/spec/camera');
    if (responseData is List) {
      return responseData.map((item) => CameraManhinh.fromJson(item)).toList();
    }
    throw Exception('Invalid response format for getAllCameraManhinh');
  }

  Future<CameraManhinh> createCameraManhinh(CameraManhinh data) async {
    final requestBody = data.toJson();
    if (requestBody['id_product'] == null) {
      throw Exception('Missing id_product when creating CameraManhinh');
    }
    final responseData =
        await _sendRequest('POST', '/spec/camera', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return CameraManhinh.fromJson(responseData);
    }
    throw Exception('Invalid response format for createCameraManhinh');
  }

  Future<CameraManhinh> updateCameraManhinh(int id, CameraManhinh data) async {
    final requestBody = data.toJson();
    final responseData =
        await _sendRequest('PUT', '/spec/camera/$id', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return CameraManhinh.fromJson(responseData);
    }
    throw Exception('Invalid response format for updateCameraManhinh');
  }

  Future<void> deleteCameraManhinh(int id) async {
    await _sendRequest('DELETE', '/spec/camera/$id');
  }

  // --- CRUD cho PinSac ---

  Future<List<PinSac>> getAllPinSac() async {
    final responseData = await _sendRequest('GET', '/spec/pinsac');
    if (responseData is List) {
      return responseData.map((item) => PinSac.fromJson(item)).toList();
    }
    throw Exception('Invalid response format for getAllPinSac');
  }

  Future<PinSac> createPinSac(PinSac data) async {
    final requestBody = data.toJson();
    if (requestBody['id_product'] == null) {
      throw Exception('Missing id_product when creating PinSac');
    }
    final responseData =
        await _sendRequest('POST', '/spec/pinsac', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return PinSac.fromJson(responseData);
    }
    throw Exception('Invalid response format for createPinSac');
  }

  Future<PinSac> updatePinSac(int id, PinSac data) async {
    final requestBody = data.toJson();
    final responseData =
        await _sendRequest('PUT', '/spec/pinsac/$id', body: requestBody);
    if (responseData is Map<String, dynamic>) {
      return PinSac.fromJson(responseData);
    }
    throw Exception('Invalid response format for updatePinSac');
  }

  Future<void> deletePinSac(int id) async {
    await _sendRequest('DELETE', '/spec/pinsac/$id');
  }
}
