import 'dart:io';

import '../../domain/entities/imported_course_entity.dart';
import '../../domain/repositories/krs_scan_repository.dart';
import '../datasources/krs_scan_remote_data_source.dart';

/// Default [KrsScanRepository] backed by the vision datasource.
final class KrsScanRepositoryImpl implements KrsScanRepository {
  const KrsScanRepositoryImpl(this._dataSource);

  final KrsScanRemoteDataSource _dataSource;

  @override
  Future<List<ImportedCourseEntity>> scanImage(File image) {
    return _dataSource.scanImage(image);
  }
}
