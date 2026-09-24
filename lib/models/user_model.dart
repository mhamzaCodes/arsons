import 'dart:convert';

/// Model representing a User account
class UserModel {
  final String id;
  final String name;
  final String phone;
  final String password;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? password,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert UserModel to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serialize to JSON string
  String toJson() => jsonEncode(toMap());

  /// Deserialize from JSON string
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source));
}
