import '../../domain/entities/course_entity.dart';

final class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.name,
    super.code,
    super.credits,
    super.lecturer,
    required super.color,
    super.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      code: _nullableString(json, 'code'),
      credits: _nullableInt(json, 'credits'),
      lecturer: _nullableString(json, 'lecturer'),
      color: _requiredString(json, 'color'),
      createdAt: _nullableDate(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'code': code,
      'credits': credits,
      'lecturer': lecturer,
      'color': color,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CourseEntity toEntity() {
    return CourseEntity(
      id: id,
      name: name,
      code: code,
      credits: credits,
      lecturer: lecturer,
      color: color,
      createdAt: createdAt,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('CourseModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('CourseModel "$key" must be a String or null.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _nullableInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('CourseModel "$key" must be an int or null.');
  }

  static DateTime? _nullableDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('CourseModel "$key" must be a String or null.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('CourseModel "$key" is not a valid timestamp.');
    }
    return parsed;
  }
}
