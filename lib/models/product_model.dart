import 'dart:convert';

/// Data Model representing a Sanitary and Tile Store Inventory Product
class ProductModel {
  final String id;
  final String name; // Urdu item name
  final String category; // Category name in Urdu
  final String company; // Company brand name in Urdu
  final double purchaseRate; // دوکاندار / خرید ریٹ
  final double wholesaleRate; // تھوک ریٹ
  final double customerRate; // گاہک ریٹ
  final String unit; // عدد / فٹ / سیٹ
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.company,
    required this.purchaseRate,
    required this.wholesaleRate,
    required this.customerRate,
    this.unit = 'عدد',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    String? company,
    double? purchaseRate,
    double? wholesaleRate,
    double? customerRate,
    String? unit,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      company: company ?? this.company,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      wholesaleRate: wholesaleRate ?? this.wholesaleRate,
      customerRate: customerRate ?? this.customerRate,
      unit: unit ?? this.unit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'company': company,
      'purchaseRate': purchaseRate,
      'wholesaleRate': wholesaleRate,
      'customerRate': customerRate,
      'unit': unit,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      company: map['company'] ?? '',
      purchaseRate: (map['purchaseRate'] as num?)?.toDouble() ?? 0.0,
      wholesaleRate: (map['wholesaleRate'] as num?)?.toDouble() ?? 0.0,
      customerRate: (map['customerRate'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'عدد',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductModel.fromJson(String source) =>
      ProductModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, category: $category, company: $company, purchaseRate: $purchaseRate, wholesaleRate: $wholesaleRate, customerRate: $customerRate, unit: $unit)';
  }
}
