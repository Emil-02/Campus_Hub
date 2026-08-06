import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_data_source.dart';

/// Bridges the course domain contract to the remote data source.
final class CourseRepositoryImpl implements CourseRepository {
  const CourseRepositoryImpl(this._remoteDataSource);

  final CourseRemoteDataSource _remoteDataSource;

  @override
  Future<List<CourseEntity>> getCourses() async {
    final models = await _remoteDataSource.getCourses();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<CourseEntity> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    final model = await _remoteDataSource.createCourse(
      name: name,
      code: code,
      credits: credits,
      lecturer: lecturer,
      color: color,
    );
    return model.toEntity();
  }

  @override
  Future<CourseEntity> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    final model = await _remoteDataSource.updateCourse(
      id: id,
      name: name,
      code: code,
      credits: credits,
      lecturer: lecturer,
      color: color,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteCourse(String id) {
    return _remoteDataSource.deleteCourse(id);
  }
}
