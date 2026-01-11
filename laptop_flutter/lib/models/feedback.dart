class FeedbackModel {
  final int id;
  final int productId;
  final int userId;
  final int? star;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackModel({
    required this.id,
    required this.productId,
    required this.userId,
    this.star,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    // this.user,
    // this.products,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      // Đổi tên key từ snake_case (DB/JSON) sang camelCase (Dart)
      productId: json['product_id'],
      userId: json['user_id'],
      star: json['star'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'star': star,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
