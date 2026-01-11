class BannerModel {
  final int id;
  final String image;
  final String? name;
  final int status; // 1: Active, 0: Inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BannerModel({
    required this.id,
    required this.image,
    this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final parsedStatus = int.tryParse(json['status']?.toString() ?? '');
    return BannerModel(
      id: json['id'] as int,
      image: json['image'] as String,
      name: json['name'] as String?,
      status: parsedStatus ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'status': status,
    };
  }
}
