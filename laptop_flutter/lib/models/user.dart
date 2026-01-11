class UserModel {
  final int id;
  final String email;
  final String name;
  final int role; // 0: User, 1: Admin
  final String? avatar;
  final String? phone;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatar,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int _safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return UserModel(
      id: _safeParseInt(json['id'],
          defaultValue: -1), // Hoặc throw lỗi nếu id là bắt buộc
      email: json['email'] as String? ?? 'N/A',
      name: json['name'] as String? ?? 'N/A',
      role:
          _safeParseInt(json['role']), // Gán giá trị mặc định nếu role là null
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatar': avatar,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [id, email, name, role, avatar, phone];
}
