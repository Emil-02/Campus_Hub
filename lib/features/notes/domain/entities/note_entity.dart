import 'package:equatable/equatable.dart';

import '../../../courses/domain/entities/course_entity.dart';

enum NoteLinkType {
  googleDrive('google_drive'),
  external('external'),
  other('other');

  const NoteLinkType(this.dbValue);

  final String dbValue;

  static NoteLinkType fromDb(String value) {
    return NoteLinkType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => NoteLinkType.other,
    );
  }

  /// NOTE-06: classify by host.
  static NoteLinkType fromUrl(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    if (host == 'drive.google.com' || host == 'docs.google.com') {
      return NoteLinkType.googleDrive;
    }
    return NoteLinkType.external;
  }
}

/// An external link attached to a note.
class NoteLinkEntity extends Equatable {
  const NoteLinkEntity({
    required this.id,
    required this.noteId,
    required this.url,
    this.title,
    this.linkType = NoteLinkType.other,
  });

  final String id;
  final String noteId;
  final String url;
  final String? title;
  final NoteLinkType linkType;

  @override
  List<Object?> get props => [id, noteId, url, title, linkType];
}

/// A rich-text study note, optionally tied to a course.
class NoteEntity extends Equatable {
  const NoteEntity({
    required this.id,
    this.courseId,
    this.course,
    required this.title,
    this.content,
    this.contentPlain,
    this.links = const [],
    this.updatedAt,
  });

  final String id;
  final String? courseId;
  final CourseEntity? course;
  final String title;

  /// Quill Delta JSON.
  final String? content;

  /// Plain text mirror used for previews and search.
  final String? contentPlain;
  final List<NoteLinkEntity> links;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    courseId,
    course,
    title,
    content,
    contentPlain,
    links,
    updatedAt,
  ];
}
