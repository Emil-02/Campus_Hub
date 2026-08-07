import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_remote_data_source.dart';

/// Bridges the note domain contract to the remote data source.
final class NoteRepositoryImpl implements NoteRepository {
  const NoteRepositoryImpl(this._remoteDataSource);

  final NoteRemoteDataSource _remoteDataSource;

  @override
  Future<List<NoteEntity>> getNotes({
    String? searchQuery,
    String? courseId,
  }) async {
    final models = await _remoteDataSource.getNotes(
      searchQuery: searchQuery,
      courseId: courseId,
    );
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<NoteEntity> createNote({
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    final model = await _remoteDataSource.createNote(
      title: title,
      content: content,
      contentPlain: contentPlain,
      courseId: courseId,
    );
    return model.toEntity();
  }

  @override
  Future<NoteEntity> updateNote({
    required String id,
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    final model = await _remoteDataSource.updateNote(
      id: id,
      title: title,
      content: content,
      contentPlain: contentPlain,
      courseId: courseId,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteNote(String id) {
    return _remoteDataSource.softDeleteNote(id);
  }

  @override
  Future<NoteLinkEntity> addLink({
    required String noteId,
    required String url,
    String? title,
  }) async {
    final model = await _remoteDataSource.addLink(
      noteId: noteId,
      url: url,
      title: title,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteLink(String id) {
    return _remoteDataSource.deleteLink(id);
  }
}
