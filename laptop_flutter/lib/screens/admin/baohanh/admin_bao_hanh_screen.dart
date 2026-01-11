import 'dart:convert'; // Để sử dụng jsonDecode

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Để format ngày
import 'package:laptop_flutter/blocs/auth/auth_bloc.dart';
import 'package:laptop_flutter/models/bao_hanh_model.dart'; // Đường dẫn tới model
import 'package:laptop_flutter/repositories/auth_repository.dart'; // Để lấy AuthRepository instance
// Import BaoHanhRepository nếu bạn tách riêng, nếu không thì dùng trực tiếp http như ví dụ
// import 'package:laptop_flutter/repositories/bao_hanh_repository.dart';

class AdminBaoHanhScreen extends StatefulWidget {
  const AdminBaoHanhScreen({Key? key}) : super(key: key);

  @override
  State<AdminBaoHanhScreen> createState() => _AdminBaoHanhScreenState();
}

class _AdminBaoHanhScreenState extends State<AdminBaoHanhScreen> {
  final TextEditingController _searchController = TextEditingController();
  // final BaoHanhRepository _baoHanhRepository = BaoHanhRepository(); // Nếu dùng repository riêng
  List<BaoHanhModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _searchQuery;
  late String _baseUrl; // Lấy baseUrl từ AuthRepository

  @override
  void initState() {
    super.initState();
    _baseUrl = context.read<AuthRepository>().baseUrl; // Khởi tạo baseUrl
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState is AuthAuthenticated) {
      return authState.token; // Lỗi sẽ hết sau khi bạn sửa AuthAuthenticated
    }
    print("Cảnh báo: Không lấy được token từ AuthState.");
    return null;
  }

  Future<void> _performSearch(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _errorMessage = null;
        _searchQuery = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchQuery = phoneNumber;
    });

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Chưa đăng nhập hoặc không có quyền Admin.');
      }

      // Sử dụng http trực tiếp hoặc qua BaoHanhRepository
      final response = await http.get(
        Uri.parse('$_baseUrl/api/baohanh/search?phone=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = body
              .map((dynamic item) =>
                  BaoHanhModel.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _searchResults = [];
        });
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(
            'Lỗi ${response.statusCode}: ${errorBody['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Lỗi tìm kiếm: ${e.toString().replaceFirst("Exception: ", "")}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Điều chỉnh độ rộng của label nếu cần
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.bold : null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Nhập SĐT khách hàng để tìm bảo hành',
              hintText: 'Ví dụ: 090xxxxxxx',
              prefixIcon: const Icon(Icons.phone_android),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _performSearch(_searchController.text.trim());
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            keyboardType: TextInputType.phone,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
              _performSearch(value.trim());
            },
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  final df = DateFormat('dd/MM/yyyy');
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mã BH: #${item.id}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Chip(
                                label: Text(item.trangThai,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                backgroundColor: item.trangThai
                                            .toLowerCase()
                                            .contains('còn') ||
                                        item.trangThai
                                            .toLowerCase()
                                            .contains('chờ')
                                    ? Colors.green
                                    : (item.trangThai
                                                .toLowerCase()
                                                .contains('hết') ||
                                            item.trangThai
                                                .toLowerCase()
                                                .contains('từ chối')
                                        ? Colors.red
                                        : Colors.orange),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (item.hinhAnhSanPham != null &&
                              item.hinhAnhSanPham!.isNotEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Image.network(
                                  item.hinhAnhSanPham!.startsWith('http')
                                      ? item.hinhAnhSanPham!
                                      : _baseUrl + item.hinhAnhSanPham!,
                                  height: 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                ),
                              ),
                            ),
                          _buildInfoRow('Sản phẩm', item.tenSanPham),
                          _buildInfoRow(
                              'Khách hàng',
                              item.tenNguoiMuaTrongDonHang ??
                                  item.tenKhachHang),
                          _buildInfoRow('SĐT', item.soDienThoaiKhachHang),
                          _buildInfoRow('Ngày giao',
                              df.format(item.ngayGiaoHang.toLocal())),
                          _buildInfoRow('Bắt đầu BH',
                              df.format(item.ngayBatDauBaoHanh.toLocal())),
                          if (item.ngayKetThucBaoHanh != null)
                            _buildInfoRow('Kết thúc BH',
                                df.format(item.ngayKetThucBaoHanh!.toLocal()),
                                valueColor: item.ngayKetThucBaoHanh!
                                        .isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.green),
                          _buildInfoRow('Thời hạn (năm)',
                              '${item.thoiGianBaoHanhNam} năm'),
                          if (item.hinhThuc != null &&
                              item.hinhThuc!.isNotEmpty)
                            _buildInfoRow('Hình thức', item.hinhThuc!),
                          if (item.ghiChu != null && item.ghiChu!.isNotEmpty)
                            _buildInfoRow('Ghi chú', item.ghiChu!),
                          //Padding(
                          //  padding: const EdgeInsets.only(top: 8.0),
                          //  child: Align(
                          //    alignment: Alignment.centerRight,
                          //    child: TextButton(
                          //      child: const Text('Xem chi tiết đơn hàng'),
                          //      onPressed: () {
                          // TODO: Điều hướng đến chi tiết đơn hàng nếu cần
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => AdminOrderDetailScreen(orderId: item.idDonHang)));
                          //ScaffoldMessenger.of(context).showSnackBar(
                          // SnackBar(
                          //     content: Text(
                          //          'Xem chi tiết đơn hàng của Mã BH: ${item.id}')),
                          // );
                          //      },
                          //    ),
                          //  ),
                          //)
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else if (_searchQuery != null && _searchQuery!.isNotEmpty)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  'Không tìm thấy thông tin bảo hành nào cho số điện thoại "$_searchQuery".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ))
          else
            Expanded(
                child: Center(
                    child: Text(
                        'Nhập số điện thoại khách hàng để tra cứu thông tin bảo hành.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[700])))),
        ],
      ),
    );
  }
}
