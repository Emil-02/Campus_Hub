import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.emailVerified,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool emailVerified;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    avatarUrl,
    emailVerified,
    createdAt,
  ];
}
