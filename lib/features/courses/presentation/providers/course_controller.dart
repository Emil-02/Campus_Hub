import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../domain/repositories/course_repository.dart';
import 'course_dependencies.dart';
import 'course_state.dart';

/// Coordinates course CRUD operations and exposes their state.
final class CourseController extends Notifier<CourseState> {
  CourseRepository get _repository => ref.read(courseRepositoryProvider);

  @override
  CourseState build() => const CourseState.initial();

  /// Loads the course list, replacing any previous data.
  Future<void> loadCourses() async {
    state = const CourseState.loading();
    try {
      final courses = await _repository.getCourses();
      state = CourseState.loaded(courses);
    } catch (error) {
      state = CourseState.failure(_safeErrorMessage(error));
    }
  }

  /// Creates a course and refreshes the list. Returns true when saved.
  Future<bool> createCourse({
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    state = CourseState.loaded(state.courses, isMutating: true);
    try {
      await _repository.createCourse(
        name: name,
        code: code,
        credits: credits,
        lecturer: lecturer,
        color: color,
      );
      await _reload();
      return true;
    } catch (error) {
      state = CourseState.failure(
        _safeErrorMessage(error),
        courses: state.courses,
      );
      return false;
    }
  }

  /// Updates a course and refreshes the list. Returns true when saved.
  Future<bool> updateCourse({
    required String id,
    required String name,
    String? code,
    int? credits,
    String? lecturer,
    required String color,
  }) async {
    state = CourseState.loaded(state.courses, isMutating: true);
    try {
      await _repository.updateCourse(
        id: id,
        name: name,
        code: code,
        credits: credits,
        lecturer: lecturer,
        color: color,
      );
      await _reload();
      return true;
    } catch (error) {
      state = CourseState.failure(
        _safeErrorMessage(error),
        courses: state.courses,
      );
      return false;
    }
  }

  /// Deletes a course and refreshes the list. Returns true when removed.
  Future<bool> deleteCourse(String id) async {
    state = CourseState.loaded(state.courses, isMutating: true);
    try {
      await _repository.deleteCourse(id);
      await _reload();
      return true;
    } catch (error) {
      state = CourseState.failure(
        _safeErrorMessage(error),
        courses: state.courses,
      );
      return false;
    }
  }

  Future<void> _reload() async {
    final courses = await _repository.getCourses();
    state = CourseState.loaded(courses);
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Course error: $error');
    if (error is PostgrestException) {
      if (error.code == '23503') {
        return 'Mata kuliah masih dipakai data lain (jadwal/tugas).';
      }
      return 'Gagal menyimpan ke server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data mata kuliah tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
