import 'dart:io';

import '../../domain/entities/captured_item_entity.dart';
import '../../domain/repositories/smart_capture_repository.dart';
import '../datasources/smart_capture_remote_data_source.dart';

/// Default [SmartCaptureRepository] backed by the AI datasource.
final class SmartCaptureRepositoryImpl implements SmartCaptureRepository {
  const SmartCaptureRepositoryImpl(this._dataSource);

  final SmartCaptureRemoteDataSource _dataSource;

  @override
  Future<List<CapturedItemEntity>> analyzeText(
    String text, {
    required List<String> courseNames,
  }) {
    return _dataSource.analyzeText(text, courseNames: courseNames);
  }

  @override
  Future<List<CapturedItemEntity>> analyzeImage(
    File image, {
    required List<String> courseNames,
  }) {
    return _dataSource.analyzeImage(image, courseNames: courseNames);
  }
}
