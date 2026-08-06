import 'package:campusmate/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'profile-1',
    'full_name': 'Emil Rahmat',
    'avatar_url': 'https://cdn.example.com/avatar.png',
    'university': 'Universitas Contoh',
    'study_program': 'Teknik Informatika',
    'degree_level': 'S1',
    'semester': 5,
  };

  test('fromJson parses a complete row', () {
    final model = ProfileModel.fromJson(validJson());

    expect(model.id, 'profile-1');
    expect(model.fullName, 'Emil Rahmat');
    expect(model.avatarUrl, 'https://cdn.example.com/avatar.png');
    expect(model.university, 'Universitas Contoh');
    expect(model.studyProgram, 'Teknik Informatika');
    expect(model.degreeLevel, 'S1');
    expect(model.semester, 5);
  });

  test('fromJson accepts null optional fields', () {
    final json = validJson()
      ..['avatar_url'] = null
      ..['university'] = null
      ..['study_program'] = null
      ..['degree_level'] = null
      ..['semester'] = null;

    final model = ProfileModel.fromJson(json);

    expect(model.avatarUrl, isNull);
    expect(model.university, isNull);
    expect(model.studyProgram, isNull);
    expect(model.degreeLevel, isNull);
    expect(model.semester, isNull);
  });

  test('fromJson treats a null full_name as empty string', () {
    final json = validJson()..['full_name'] = null;

    expect(ProfileModel.fromJson(json).fullName, '');
  });

  test('fromJson rejects a missing id', () {
    final json = validJson()..['id'] = '';

    expect(() => ProfileModel.fromJson(json), throwsFormatException);
  });

  test('fromJson rejects a non-numeric semester', () {
    final json = validJson()..['semester'] = 'lima';

    expect(() => ProfileModel.fromJson(json), throwsFormatException);
  });

  test('toEntity keeps every field', () {
    final entity = ProfileModel.fromJson(validJson()).toEntity();

    expect(entity.fullName, 'Emil Rahmat');
    expect(entity.degreeLevel, 'S1');
    expect(entity.semester, 5);
  });
}
