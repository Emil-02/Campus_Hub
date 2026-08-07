import '../../../courses/data/models/course_model.dart';
import '../../domain/entities/note_entity.dart';

final class NoteLinkModel extends NoteLinkEntity {
  const NoteLinkModel({
    required super.id,
    required super.noteId,
    required super.url,
    super.title,
    super.linkType,
  });

  factory NoteLinkModel.fromJson(Map<String, dynamic> json) {
    return NoteLinkModel(
      id: _requiredString(json, 'id'),
      noteId: _requiredString(json, 'note_id'),
      url: _requiredString(json, 'url'),
      title: _nullableString(json, 'title'),
      linkType: NoteLinkType.fromDb(json['link_type'] as String? ?? 'other'),
    );
  }

  NoteLinkEntity toEntity() {
    return NoteLinkEntity(
      id: id,
      noteId: noteId,
      url: url,
      title: title,
      linkType: linkType,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('NoteLinkModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('NoteLinkModel "$key" must be a String or null.');
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

final class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    super.courseId,
    super.course,
    required super.title,
    super.content,
    super.contentPlain,
    super.links,
    super.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final courseJson = json['courses'];
    final linksJson = json['note_links'];

    return NoteModel(
      id: _requiredString(json, 'id'),
      courseId: _nullableString(json, 'course_id'),
      course: courseJson is Map<String, dynamic>
          ? CourseModel.fromJson(courseJson).toEntity()
          : null,
      title: _requiredString(json, 'title'),
      content: _nullableString(json, 'content'),
      contentPlain: _nullableString(json, 'content_plain'),
      links: linksJson is List
          ? linksJson
                .whereType<Map<String, dynamic>>()
                .map(NoteLinkModel.fromJson)
                .toList(growable: false)
          : const [],
      updatedAt: _nullableDate(json, 'updated_at'),
    );
  }

  NoteEntity toEntity() {
    return NoteEntity(
      id: id,
      courseId: courseId,
      course: course,
      title: title,
      content: content,
      contentPlain: contentPlain,
      links: links,
      updatedAt: updatedAt,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('NoteModel "$key" must be a non-empty String.');
    }
    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('NoteModel "$key" must be a String or null.');
    }
    return value;
  }

  static DateTime? _nullableDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('NoteModel "$key" must be a String or null.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('NoteModel "$key" is not a valid timestamp.');
    }
    return parsed.toLocal();
  }
}
