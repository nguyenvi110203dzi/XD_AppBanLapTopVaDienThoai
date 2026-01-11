class CauhinhBonho {
  final int id;
  final String hedieuhanh;
  final String? chipCPU;
  final String? tocdoCPU;
  final String? chipDohoa;
  final String? ram;
  final String? dungluongLuutru;
  final String? dungluongKhadung;
  final String? thenho;
  final String? danhba;
  final int idProduct;

  const CauhinhBonho({
    required this.id,
    required this.hedieuhanh,
    this.chipCPU,
    this.tocdoCPU,
    this.chipDohoa,
    this.ram,
    this.dungluongLuutru,
    this.dungluongKhadung,
    this.thenho,
    this.danhba,
    required this.idProduct,
  });

  factory CauhinhBonho.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse int, handling null or incorrect types
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    return CauhinhBonho(
      id: safeParseInt(json['id']),
      hedieuhanh:
          json['hedieuhanh'] as String? ?? 'N/A', // Default value if null
      chipCPU: json['chip_CPU'] as String?,
      tocdoCPU: json['tocdo_CPU'] as String?,
      chipDohoa: json['chip_dohoa'] as String?,
      ram: json['ram'] as String?,
      dungluongLuutru: json['dungluong_luutru'] as String?,
      dungluongKhadung: json['dungluong_khadung'] as String?,
      thenho: json['thenho'] as String?,
      danhba: json['danhba'] as String?,
      idProduct: safeParseInt(json['id_product']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hedieuhanh': hedieuhanh,
      'chip_CPU': chipCPU,
      'tocdo_CPU': tocdoCPU,
      'chip_dohoa': chipDohoa,
      'ram': ram,
      'dungluong_luutru': dungluongLuutru,
      'dungluong_khadung': dungluongKhadung,
      'thenho': thenho,
      'danhba': danhba,
      'id_product': idProduct,
    };
  }
}
