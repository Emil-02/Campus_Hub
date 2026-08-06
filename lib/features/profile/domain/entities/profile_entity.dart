import 'package:equatable/equatable.dart';

/// Academic profile of the authenticated student.
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.university,
    this.studyProgram,
    this.degreeLevel,
    this.semester,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? university;
  final String? studyProgram;

  /// One of `D3`, `D4`, `S1`.
  final String? degreeLevel;
  final int? semester;

  @override
  List<Object?> get props => [
    id,
    fullName,
    avatarUrl,
    university,
    studyProgram,
    degreeLevel,
    semester,
  ];
}
