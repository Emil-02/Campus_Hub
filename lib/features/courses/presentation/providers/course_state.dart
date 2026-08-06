import 'package:equatable/equatable.dart';

import '../../domain/entities/course_entity.dart';

enum CourseStatus { initial, loading, loaded, failure }

/// Immutable state for the course list and its mutations.
class CourseState extends Equatable {
  const CourseState._({
    required this.status,
    this.courses = const [],
    this.errorMessage,
    this.isMutating = false,
  });

  const CourseState.initial() : this._(status: CourseStatus.initial);

  const CourseState.loading() : this._(status: CourseStatus.loading);

  const CourseState.loaded(
    List<CourseEntity> courses, {
    bool isMutating = false,
  }) : this._(
         status: CourseStatus.loaded,
         courses: courses,
         isMutating: isMutating,
       );

  const CourseState.failure(
    String message, {
    List<CourseEntity> courses = const [],
  }) : this._(
         status: CourseStatus.failure,
         errorMessage: message,
         courses: courses,
       );

  final CourseStatus status;
  final List<CourseEntity> courses;
  final String? errorMessage;

  /// True while a create/update/delete request is in flight.
  final bool isMutating;

  @override
  List<Object?> get props => [status, courses, errorMessage, isMutating];
}
