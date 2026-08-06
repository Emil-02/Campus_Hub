import '../../domain/entities/profile_entity.dart';

final class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.fullName,
    super.avatarUrl,
    super.university,
    super.studyProgram,
    super.degreeLevel,
    super.semester,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: _requiredString(json, 'id'),
      fullName: _stringOrEmpty(json, 'full_name'),
      avatarUrl: _nullableString(json, 'avatar_url'),
      university: _nullableString(json, 'university'),
      studyProgram: _nullableString(json, 'study_program'),
      degreeLevel: _nullableString(json, 'degree_level'),
      semester: _nullableInt(json, 'semester'),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'university': university,
      'study_program': studyProgram,
      'degree_level': degreeLevel,
      'semester': semester,
    };
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      fullName: fullName,
      avatarUrl: avatarUrl,
      university: university,
      studyProgram: studyProgram,
      degreeLevel: degreeLevel,
      semester: semester,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('ProfileModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String _stringOrEmpty(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return '';
    }
    if (value is! String) {
      throw FormatException('ProfileModel "$key" must be a String.');
    }
    return value.trim();
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('ProfileModel "$key" must be a String or null.');
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
    throw FormatException('ProfileModel "$key" must be an int or null.');
  }
}
