import 'package:campusmate/features/auth/data/models/user_model.dart';
import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    final createdAt = DateTime.utc(2026, 7, 26, 12, 30);
    final model = UserModel(
      id: 'user-1',
      email: 'student@example.com',
      fullName: 'CampusMate Student',
      avatarUrl: 'https://example.com/avatar.png',
      emailVerified: true,
      createdAt: createdAt,
    );

    test('fromJson maps every field correctly', () {
      final result = UserModel.fromJson(const <String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
        'full_name': 'CampusMate Student',
        'avatar_url': 'https://example.com/avatar.png',
        'email_verified': true,
        'created_at': '2026-07-26T12:30:00.000Z',
      });

      expect(result, equals(model));
    });

    test('fromJson supports nullable fields', () {
      final result = UserModel.fromJson(const <String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
        'full_name': null,
        'avatar_url': null,
        'email_verified': false,
        'created_at': null,
      });

      expect(result.fullName, isNull);
      expect(result.avatarUrl, isNull);
      expect(result.createdAt, isNull);
    });

    test('fromJson supports an ISO-8601 created_at String', () {
      final result = UserModel.fromJson(const <String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
        'created_at': '2026-07-26T12:30:00.000Z',
      });

      expect(result.createdAt, equals(createdAt));
    });

    test('fromJson supports a DateTime created_at value', () {
      final result = UserModel.fromJson(<String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
        'created_at': createdAt,
      });

      expect(result.createdAt, same(createdAt));
    });

    test('fromJson defaults email_verified to false when absent', () {
      final result = UserModel.fromJson(const <String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
      });

      expect(result.emailVerified, isFalse);
    });

    test('fromJson throws FormatException for a missing or invalid id', () {
      final invalidValues = <Object?>[null, 1, ''];

      for (final invalidValue in invalidValues) {
        expect(
          () => UserModel.fromJson(<String, dynamic>{
            'id': invalidValue,
            'email': 'student@example.com',
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('id'),
            ),
          ),
        );
      }
    });

    test('fromJson throws FormatException for a missing or invalid email', () {
      final invalidValues = <Object?>[null, 1, ''];

      for (final invalidValue in invalidValues) {
        expect(
          () => UserModel.fromJson(<String, dynamic>{
            'id': 'user-1',
            'email': invalidValue,
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('email'),
            ),
          ),
        );
      }
    });

    test('toJson returns the expected JSON-safe map', () {
      expect(model.toJson(), <String, dynamic>{
        'id': 'user-1',
        'email': 'student@example.com',
        'full_name': 'CampusMate Student',
        'avatar_url': 'https://example.com/avatar.png',
        'email_verified': true,
        'created_at': '2026-07-26T12:30:00.000Z',
      });
    });

    test('toJson output can be read without losing data', () {
      final roundTripModel = UserModel.fromJson(model.toJson());

      expect(roundTripModel, equals(model));
    });

    test('toEntity maps every value to a UserEntity', () {
      final entity = model.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.runtimeType, UserEntity);
      expect(entity.id, model.id);
      expect(entity.email, model.email);
      expect(entity.fullName, model.fullName);
      expect(entity.avatarUrl, model.avatarUrl);
      expect(entity.emailVerified, model.emailVerified);
      expect(entity.createdAt, model.createdAt);
    });

    test('equality includes every field', () {
      final equalModel = UserModel(
        id: model.id,
        email: model.email,
        fullName: model.fullName,
        avatarUrl: model.avatarUrl,
        emailVerified: model.emailVerified,
        createdAt: model.createdAt,
      );
      final variants = <UserModel>[
        UserModel(
          id: 'different-id',
          email: model.email,
          fullName: model.fullName,
          avatarUrl: model.avatarUrl,
          emailVerified: model.emailVerified,
          createdAt: model.createdAt,
        ),
        UserModel(
          id: model.id,
          email: 'different@example.com',
          fullName: model.fullName,
          avatarUrl: model.avatarUrl,
          emailVerified: model.emailVerified,
          createdAt: model.createdAt,
        ),
        UserModel(
          id: model.id,
          email: model.email,
          fullName: 'Different Name',
          avatarUrl: model.avatarUrl,
          emailVerified: model.emailVerified,
          createdAt: model.createdAt,
        ),
        UserModel(
          id: model.id,
          email: model.email,
          fullName: model.fullName,
          avatarUrl: 'https://example.com/different.png',
          emailVerified: model.emailVerified,
          createdAt: model.createdAt,
        ),
        UserModel(
          id: model.id,
          email: model.email,
          fullName: model.fullName,
          avatarUrl: model.avatarUrl,
          emailVerified: false,
          createdAt: model.createdAt,
        ),
        UserModel(
          id: model.id,
          email: model.email,
          fullName: model.fullName,
          avatarUrl: model.avatarUrl,
          emailVerified: model.emailVerified,
          createdAt: DateTime.utc(2026, 7, 27),
        ),
      ];

      expect(model, equals(equalModel));
      for (final variant in variants) {
        expect(model, isNot(equals(variant)));
      }
    });
  });
}
