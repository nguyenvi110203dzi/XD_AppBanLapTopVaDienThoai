// lib/models/bao_hanh_model.dart
import 'package:intl/intl.dart'; // Để định dạng ngày

class BaoHanhModel {
  final int id;
  final int idChiTietDonHang;
  final String soDienThoaiKhachHang;
  final String tenKhachHang;
  final String tenSanPham;
  final DateTime ngayGiaoHang;
  final DateTime ngayBatDauBaoHanh;
  final int thoiGianBaoHanhNam;
  final DateTime? ngayKetThucBaoHanh;
  final String trangThai;
  final String? hinhThuc;
  final String? ghiChu;
  final DateTime ngayTao;
  final DateTime ngayCapNhat;
  // Thêm các trường từ Product, Order, User nếu API của bạn trả về (trong `chiTietDonHangLienQuan`)
  final String? hinhAnhSanPham; // Ví dụ
  final String? tenNguoiMuaTrongDonHang; // Ví dụ

  BaoHanhModel({
    required this.id,
    required this.idChiTietDonHang,
    required this.soDienThoaiKhachHang,
    required this.tenKhachHang,
    required this.tenSanPham,
    required this.ngayGiaoHang,
    required this.ngayBatDauBaoHanh,
    required this.thoiGianBaoHanhNam,
    this.ngayKetThucBaoHanh,
    required this.trangThai,
    this.hinhThuc,
    this.ghiChu,
    required this.ngayTao,
    required this.ngayCapNhat,
    this.hinhAnhSanPham,
    this.tenNguoiMuaTrongDonHang,
  });

  factory BaoHanhModel.fromJson(Map<String, dynamic> json) {
    String? extractedHinhAnhSanPham;
    String? extractedTenNguoiMua;

    if (json['chiTietDonHangLienQuan'] != null) {
      final chiTiet = json['chiTietDonHangLienQuan'];
      if (chiTiet['product'] != null) {
        extractedHinhAnhSanPham =
            chiTiet['product']['image']; // Giả sử trường là 'image'
      }
      if (chiTiet['order'] != null && chiTiet['order']['user'] != null) {
        extractedTenNguoiMua = chiTiet['order']['user']['name'];
      }
    }

    return BaoHanhModel(
      id: json['id'],
      idChiTietDonHang: json['id_chi_tiet_don_hang'],
      soDienThoaiKhachHang: json['so_dien_thoai_khach_hang'],
      tenKhachHang: json['ten_khach_hang'],
      tenSanPham: json['ten_san_pham'],
      ngayGiaoHang: DateTime.parse(json['ngay_giao_hang']),
      ngayBatDauBaoHanh: DateTime.parse(json['ngay_bat_dau_bao_hanh']),
      thoiGianBaoHanhNam: json['thoi_gian_bao_hanh_nam'],
      ngayKetThucBaoHanh: json['ngay_ket_thuc_bao_hanh'] != null
          ? DateTime.parse(json['ngay_ket_thuc_bao_hanh'])
          : null,
      trangThai: json['trang_thai'],
      hinhThuc: json['hinh_thuc'],
      ghiChu: json['ghi_chu'],
      ngayTao: DateTime.parse(json['ngay_tao']),
      ngayCapNhat: DateTime.parse(json['ngay_cap_nhat']),
      hinhAnhSanPham: extractedHinhAnhSanPham,
      tenNguoiMuaTrongDonHang: extractedTenNguoiMua,
    );
  }
  // Hàm tiện ích để hiển thị ngày tháng đã định dạng
  String get ngayGiaoHangFormatted =>
      DateFormat('dd/MM/yyyy').format(ngayGiaoHang);
  String get ngayBatDauBaoHanhFormatted =>
      DateFormat('dd/MM/yyyy').format(ngayBatDauBaoHanh);
  String get ngayKetThucBaoHanhFormatted {
    if (ngayKetThucBaoHanh != null) {
      return DateFormat('dd/MM/yyyy').format(ngayKetThucBaoHanh!);
    }
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime(
          ngayBatDauBaoHanh.year + thoiGianBaoHanhNam,
          ngayBatDauBaoHanh.month,
          ngayBatDauBaoHanh.day));
    } catch (e) {
      return 'N/A';
    }
  }

  String get ngayTaoFormatted => DateFormat('dd/MM/yyyy HH:mm').format(ngayTao);
  String get ngayCapNhatFormatted =>
      DateFormat('dd/MM/yyyy HH:mm').format(ngayCapNhat);
}
