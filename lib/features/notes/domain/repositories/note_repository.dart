import '../entities/note_entity.dart';

/// Contract for note data operations.
abstract interface class NoteRepository {
  /// Returns non-deleted notes, optionally narrowed by search or course.
  Future<List<NoteEntity>> getNotes({String? searchQuery, String? courseId});

  Future<NoteEntity> createNote({
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  });

  Future<NoteEntity> updateNote({
    required String id,
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  });

  /// BR-06: soft delete.
  Future<void> deleteNote(String id);

  Future<NoteLinkEntity> addLink({
    required String noteId,
    required String url,
    String? title,
  });

  Future<void> deleteLink(String id);
}
