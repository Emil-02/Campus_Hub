import '../entities/course_entity.dart';

/// Contract for course data operations.
abstract interface class CourseRepository {
  Future<List<CourseEntity>> getCourses();

  Future<CourseEntity> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  });

  Future<CourseEntity> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  });

  Future<void> deleteCourse(String id);
}
