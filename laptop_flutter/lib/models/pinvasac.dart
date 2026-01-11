class PinSac {
  final int id;
  final String dungluongPin;
  final String? loaiPin;
  final String? hotrosacMax;
  final String? sacTheomay;
  final String? congnghePin;
  final int idProduct;

  const PinSac({
    required this.id,
    required this.dungluongPin,
    this.loaiPin,
    this.hotrosacMax,
    this.sacTheomay,
    this.congnghePin,
    required this.idProduct,
  });

  factory PinSac.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    return PinSac(
      id: safeParseInt(json['id']),
      dungluongPin: json['dungluong_pin'] as String? ?? 'N/A',
      loaiPin: json['loai_pin'] as String?,
      hotrosacMax: json['hotrosac_max'] as String?,
      sacTheomay: json['sac_theomay'] as String?,
      congnghePin: json['congnghe_pin'] as String?,
      idProduct: safeParseInt(json['id_product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dungluong_pin': dungluongPin,
      'loai_pin': loaiPin,
      'hotrosac_max': hotrosacMax,
      'sac_theomay': sacTheomay,
      'congnghe_pin': congnghePin,
      'id_product': idProduct,
    };
  }
}
