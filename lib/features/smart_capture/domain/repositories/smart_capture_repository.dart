import 'dart:io';

import '../entities/captured_item_entity.dart';

/// Contract for concluding tasks/events from raw text or a photo.
abstract interface class SmartCaptureRepository {
  /// Analyzes pasted chat text. [courseNames] helps AI match courses.
  Future<List<CapturedItemEntity>> analyzeText(
    String text, {
    required List<String> courseNames,
  });

  /// Analyzes a photo (chat screenshot/announcement).
  Future<List<CapturedItemEntity>> analyzeImage(
    File image, {
    required List<String> courseNames,
  });
}
