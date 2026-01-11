class CameraManhinh {
  final int id;
  final String dophangiaiCamsau;
  final String? congngheCamsau;
  final bool? denflashCamsau; // Kiểu bool? cho TINYINT(1)
  final String? tinhnangCamsau;
  final String? dophangiaiCamtruoc;
  final String? tinhnangCamtruoc;
  final String? congngheManhinh;
  final String? dophangiaiManhinh;
  final String? rongManhinh;
  final String? dosangManhinh;
  final String? matkinhManhinh;
  final int idProduct;

  const CameraManhinh({
    required this.id,
    required this.dophangiaiCamsau,
    this.congngheCamsau,
    this.denflashCamsau,
    this.tinhnangCamsau,
    this.dophangiaiCamtruoc,
    this.tinhnangCamtruoc,
    this.congngheManhinh,
    this.dophangiaiManhinh,
    this.rongManhinh,
    this.dosangManhinh,
    this.matkinhManhinh,
    required this.idProduct,
  });

  factory CameraManhinh.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    // Chuyển đổi giá trị TINYINT(1) hoặc boolean từ JSON sang bool?
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return null;
    }

    return CameraManhinh(
      id: safeParseInt(json['id']),
      dophangiaiCamsau: json['dophangiai_camsau'] as String? ?? 'N/A',
      congngheCamsau: json['congnghe_camsau'] as String?,
      denflashCamsau:
          parseBool(json['denflash_camsau']), // Sử dụng hàm parseBool
      tinhnangCamsau: json['tinhnang_camsau'] as String?,
      dophangiaiCamtruoc: json['dophangiai_camtruoc'] as String?,
      tinhnangCamtruoc: json['tinhnang_camtruoc'] as String?,
      congngheManhinh: json['congnghe_manhinh'] as String?,
      dophangiaiManhinh: json['dophangiai_manhinh'] as String?,
      rongManhinh: json['rong_manhinh'] as String?,
      dosangManhinh: json['dosang_manhinh'] as String?,
      matkinhManhinh: json['matkinh_manhinh'] as String?,
      idProduct: safeParseInt(json['id_product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dophangiai_camsau': dophangiaiCamsau,
      'congnghe_camsau': congngheCamsau,
      'denflash_camsau': denflashCamsau == null
          ? null
          : (denflashCamsau! ? 1 : 0), // Chuyển bool? về 1/0/null
      'tinhnang_camsau': tinhnangCamsau,
      'dophangiai_camtruoc': dophangiaiCamtruoc,
      'tinhnang_camtruoc': tinhnangCamtruoc,
      'congnghe_manhinh': congngheManhinh,
      'dophangiai_manhinh': dophangiaiManhinh,
      'rong_manhinh': rongManhinh,
      'dosang_manhinh': dosangManhinh,
      'matkinh_manhinh': matkinhManhinh,
      'id_product': idProduct,
    };
  }
}
