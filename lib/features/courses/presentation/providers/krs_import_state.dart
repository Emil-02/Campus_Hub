import 'package:equatable/equatable.dart';

import '../../domain/entities/imported_course_entity.dart';

enum KrsImportStatus { idle, scanning, review, importing, failure }

/// One reviewable row from the scan with its selection state.
class KrsImportRow extends Equatable {
  const KrsImportRow({
    required this.course,
    required this.selected,
    required this.isDuplicate,
  });

  final ImportedCourseEntity course;
  final bool selected;

  /// True when a course with the same code/name already exists.
  final bool isDuplicate;

  KrsImportRow copyWith({bool? selected}) {
    return KrsImportRow(
      course: course,
      selected: selected ?? this.selected,
      isDuplicate: isDuplicate,
    );
  }

  @override
  List<Object?> get props => [course, selected, isDuplicate];
}

/// Immutable state for the photo-import flow.
class KrsImportState extends Equatable {
  const KrsImportState._({
    required this.status,
    this.rows = const [],
    this.errorMessage,
    this.importedCourses = 0,
    this.importedSchedules = 0,
  });

  const KrsImportState.idle() : this._(status: KrsImportStatus.idle);

  const KrsImportState.scanning() : this._(status: KrsImportStatus.scanning);

  const KrsImportState.review(List<KrsImportRow> rows)
    : this._(status: KrsImportStatus.review, rows: rows);

  const KrsImportState.importing(List<KrsImportRow> rows)
    : this._(status: KrsImportStatus.importing, rows: rows);

  const KrsImportState.failure(
    String message, {
    List<KrsImportRow> rows = const [],
  }) : this._(
         status: KrsImportStatus.failure,
         errorMessage: message,
         rows: rows,
       );

  const KrsImportState.done({
    required int importedCourses,
    required int importedSchedules,
  }) : this._(
         status: KrsImportStatus.idle,
         importedCourses: importedCourses,
         importedSchedules: importedSchedules,
       );

  final KrsImportStatus status;
  final List<KrsImportRow> rows;
  final String? errorMessage;
  final int importedCourses;
  final int importedSchedules;

  int get selectedCount => rows.where((row) => row.selected).length;

  @override
  List<Object?> get props => [
    status,
    rows,
    errorMessage,
    importedCourses,
    importedSchedules,
  ];
}
