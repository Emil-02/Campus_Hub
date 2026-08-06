import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_model.dart';

/// Remote operations for the `courses` table.
abstract interface class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses();

  Future<CourseModel> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  });

  Future<CourseModel> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  });

  Future<void> deleteCourse(String id);
}

/// Implements course operations using the injected Supabase client.
final class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  const CourseRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CourseModel>> getCourses() async {
    final rows = await _client
        .from('courses')
        .select()
        .order('name', ascending: true);
    return rows.map(CourseModel.fromJson).toList(growable: false);
  }

  @override
  Future<CourseModel> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required to create a course.');
    }

    final row = await _client
        .from('courses')
        .insert({
          'user_id': userId,
          'name': name,
          'code': code,
          'credits': credits,
          'lecturer': lecturer,
          'color': color,
        })
        .select()
        .single();
    return CourseModel.fromJson(row);
  }

  @override
  Future<CourseModel> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    final row = await _client
        .from('courses')
        .update({
          'name': name,
          'code': code,
          'credits': credits,
          'lecturer': lecturer,
          'color': color,
        })
        .eq('id', id)
        .select()
        .single();
    return CourseModel.fromJson(row);
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }
}
