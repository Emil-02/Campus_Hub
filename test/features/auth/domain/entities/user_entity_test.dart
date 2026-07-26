import 'package:campusmate/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserEntity', () {
    final createdAt = DateTime.utc(2026, 7, 26);
    final entity = UserEntity(
      id: 'user-1',
      email: 'student@example.com',
      fullName: 'CampusMate Student',
      avatarUrl: 'https://example.com/avatar.png',
      emailVerified: true,
      createdAt: createdAt,
    );

    test('considers entities with identical values equal', () {
      final identicalEntity = UserEntity(
        id: 'user-1',
        email: 'student@example.com',
        fullName: 'CampusMate Student',
        avatarUrl: 'https://example.com/avatar.png',
        emailVerified: true,
        createdAt: createdAt,
      );

      expect(entity, equals(identicalEntity));
      expect(entity.hashCode, equals(identicalEntity.hashCode));
    });

    test('considers entities with different values unequal', () {
      const differentEntity = UserEntity(
        id: 'user-2',
        email: 'another@example.com',
        emailVerified: false,
      );

      expect(entity, isNot(equals(differentEntity)));
    });

    test('supports nullable fields', () {
      const entityWithNulls = UserEntity(
        id: 'user-1',
        email: 'student@example.com',
        emailVerified: false,
      );

      expect(entityWithNulls.fullName, isNull);
      expect(entityWithNulls.avatarUrl, isNull);
      expect(entityWithNulls.createdAt, isNull);
    });

    test('includes every field in equality', () {
      final variants = <UserEntity>[
        UserEntity(
          id: 'different-id',
          email: entity.email,
          fullName: entity.fullName,
          avatarUrl: entity.avatarUrl,
          emailVerified: entity.emailVerified,
          createdAt: entity.createdAt,
        ),
        UserEntity(
          id: entity.id,
          email: 'different@example.com',
          fullName: entity.fullName,
          avatarUrl: entity.avatarUrl,
          emailVerified: entity.emailVerified,
          createdAt: entity.createdAt,
        ),
        UserEntity(
          id: entity.id,
          email: entity.email,
          fullName: 'Different Name',
          avatarUrl: entity.avatarUrl,
          emailVerified: entity.emailVerified,
          createdAt: entity.createdAt,
        ),
        UserEntity(
          id: entity.id,
          email: entity.email,
          fullName: entity.fullName,
          avatarUrl: 'https://example.com/different.png',
          emailVerified: entity.emailVerified,
          createdAt: entity.createdAt,
        ),
        UserEntity(
          id: entity.id,
          email: entity.email,
          fullName: entity.fullName,
          avatarUrl: entity.avatarUrl,
          emailVerified: false,
          createdAt: entity.createdAt,
        ),
        UserEntity(
          id: entity.id,
          email: entity.email,
          fullName: entity.fullName,
          avatarUrl: entity.avatarUrl,
          emailVerified: entity.emailVerified,
          createdAt: DateTime.utc(2026, 7, 27),
        ),
      ];

      for (final variant in variants) {
        expect(entity, isNot(equals(variant)));
      }
    });
  });
}
