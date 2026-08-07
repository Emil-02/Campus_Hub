import 'package:campusmate/features/notes/data/models/note_model.dart';
import 'package:campusmate/features/notes/domain/entities/note_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validJson() => <String, dynamic>{
    'id': 'note-1',
    'course_id': 'course-1',
    'courses': {
      'id': 'course-1',
      'name': 'Struktur Data',
      'color': '#4A90D9',
    },
    'title': 'Ringkasan bab 1',
    'content': '[{"insert":"Halo\\n"}]',
    'content_plain': 'Halo',
    'updated_at': '2026-08-06T10:00:00.000Z',
    'note_links': [
      {
        'id': 'link-1',
        'note_id': 'note-1',
        'url': 'https://drive.google.com/file/d/abc',
        'title': 'Materi',
        'link_type': 'google_drive',
      },
    ],
  };

  test('fromJson parses a complete row with nested course and links', () {
    final model = NoteModel.fromJson(validJson());

    expect(model.id, 'note-1');
    expect(model.course?.name, 'Struktur Data');
    expect(model.title, 'Ringkasan bab 1');
    expect(model.contentPlain, 'Halo');
    expect(model.links, hasLength(1));
    expect(model.links.first.linkType, NoteLinkType.googleDrive);
  });

  test('fromJson accepts missing optional fields', () {
    final json = validJson()
      ..['course_id'] = null
      ..['courses'] = null
      ..['content'] = null
      ..['content_plain'] = null
      ..['note_links'] = null
      ..['updated_at'] = null;

    final model = NoteModel.fromJson(json);

    expect(model.course, isNull);
    expect(model.content, isNull);
    expect(model.links, isEmpty);
    expect(model.updatedAt, isNull);
  });

  test('fromJson rejects an empty title', () {
    final json = validJson()..['title'] = '';

    expect(() => NoteModel.fromJson(json), throwsFormatException);
  });

  test('link type falls back to other on unknown values', () {
    final json = validJson();
    (json['note_links'] as List).first['link_type'] = 'nonsense';

    expect(NoteModel.fromJson(json).links.first.linkType, NoteLinkType.other);
  });

  test('fromUrl classifies Google Drive and external hosts', () {
    expect(
      NoteLinkType.fromUrl('https://drive.google.com/file/d/xyz'),
      NoteLinkType.googleDrive,
    );
    expect(
      NoteLinkType.fromUrl('https://docs.google.com/document/d/xyz'),
      NoteLinkType.googleDrive,
    );
    expect(
      NoteLinkType.fromUrl('https://example.com/materi'),
      NoteLinkType.external,
    );
  });
}
