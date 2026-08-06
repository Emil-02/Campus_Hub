import 'package:equatable/equatable.dart';

/// A course owned by the authenticated user.
class CourseEntity extends Equatable {
  const CourseEntity({
    required this.id,
    required this.name,
    this.code,
    this.credits,
    this.lecturer,
    required this.color,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? code;
  final int? credits;
  final String? lecturer;

  /// Hex color in the form `#RRGGBB`.
  final String color;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    credits,
    lecturer,
    color,
    createdAt,
  ];
}
