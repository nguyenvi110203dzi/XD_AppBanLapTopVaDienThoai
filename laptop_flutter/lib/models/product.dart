import 'package:laptop_flutter/models/pinvasac.dart';

import 'brand.dart';
import 'cameramanhinh.dart';
import 'category.dart';
import 'cauhinhbonho.dart'; // Import các model mới

class ProductModel {
  final int id;
  final String name;
  final int price;
  final int? oldprice;
  final String? image;
  final String? description;
  final String? specification; // Trường cũ, có thể vẫn dùng
  final int buyturn;
  final int quantity;
  final int brandId;
  final int categoryId;
  final Brand? brand;
  final Category? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? time_baohanh;
  // Các đối tượng chứa thông tin chi tiết
  final CauhinhBonho? cauhinhBonho;
  final CameraManhinh? cameraManhinh;
  final PinSac? pinSac;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.oldprice,
    this.image,
    this.description,
    this.specification,
    required this.buyturn,
    required this.quantity,
    required this.brandId,
    required this.categoryId,
    this.brand,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.time_baohanh,
    this.cauhinhBonho,
    this.cameraManhinh,
    this.pinSac,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      if (value is double) return value.toInt();
      return defaultValue;
    }

    T? safeParseNestedObject<T>(
        dynamic data, T Function(Map<String, dynamic>) fromJson) {
      if (data != null && data is Map<String, dynamic>) {
        try {
          if (data.isEmpty) return null;
          return fromJson(data);
        } catch (e) {
          print("Error parsing nested object ($T): $e. Data: $data");
          return null;
        }
      }
      return null;
    }

    DateTime? safeParseDateTime(dynamic value) {
      if (value == null || value is! String) return null;
      return DateTime.tryParse(value)?.toLocal();
    }

    return ProductModel(
      id: safeParseInt(json['id']),
      name: json['name'] as String? ?? 'Unknown Product',
      price: safeParseInt(json['price']),
      oldprice: safeParseInt(json['oldprice'], defaultValue: -1) == -1
          ? null
          : safeParseInt(json['oldprice']),
      image: json['image'] as String?,
      description: json['description'] as String?,
      specification: json['specification'] as String?,
      buyturn: safeParseInt(json['buyturn']),
      quantity: safeParseInt(json['quantity']),
      brandId: safeParseInt(json['brand_id']),
      categoryId: safeParseInt(json['category_id']),
      brand: safeParseNestedObject(json['brand'], Brand.fromJson),
      category: safeParseNestedObject(json['category'], Category.fromJson),
      cauhinhBonho:
          safeParseNestedObject(json['cauhinh_bonho'], CauhinhBonho.fromJson),
      cameraManhinh:
          safeParseNestedObject(json['camera_manhinh'], CameraManhinh.fromJson),
      pinSac: safeParseNestedObject(json['pin_sac'], PinSac.fromJson),
      time_baohanh: json['time_baohanh'] as String?,
      createdAt: safeParseDateTime(json['createdAt']),
      updatedAt: safeParseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'oldprice': oldprice,
      'image': image,
      'description': description,
      'specification': specification,
      'buyturn': buyturn,
      'quantity': quantity,
      'brand_id': brandId,
      'category_id': categoryId,
      'time_baohanh': time_baohanh,
    };
  }
}
