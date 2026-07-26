import '../../domain/entities/user_entity.dart';

final class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.avatarUrl,
    required super.emailVerified,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      fullName: _nullableString(json, 'full_name'),
      avatarUrl: _nullableString(json, 'avatar_url'),
      emailVerified: _emailVerified(json['email_verified']),
      createdAt: _createdAt(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email_verified': emailVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      emailVerified: emailVerified,
      createdAt: createdAt,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('UserModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('UserModel "$key" must be a String or null.');
    }
    return value;
  }

  static bool _emailVerified(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is! bool) {
      throw const FormatException('UserModel "email_verified" must be a bool.');
    }
    return value;
  }

  static DateTime? _createdAt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsedValue = DateTime.tryParse(value);
      if (parsedValue != null) {
        return parsedValue;
      }
    }
    throw const FormatException(
      'UserModel "created_at" must be an ISO-8601 String, DateTime, or null.',
    );
  }
}
