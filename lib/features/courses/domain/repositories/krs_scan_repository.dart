import 'dart:io';

import '../entities/imported_course_entity.dart';

/// Contract for extracting course rows from a KRS photo.
abstract interface class KrsScanRepository {
  /// Reads the photo and returns the detected course rows.
  Future<List<ImportedCourseEntity>> scanImage(File image);
}
