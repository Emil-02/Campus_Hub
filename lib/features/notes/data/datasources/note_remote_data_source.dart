import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/note_entity.dart';
import '../models/note_model.dart';

const _noteSelect = '*, courses(*), note_links(*)';

/// Remote operations for the `notes` and `note_links` tables.
abstract interface class NoteRemoteDataSource {
  Future<List<NoteModel>> getNotes({String? searchQuery, String? courseId});

  Future<NoteModel> createNote({
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  });

  Future<NoteModel> updateNote({
    required String id,
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  });

  Future<void> softDeleteNote(String id);

  Future<NoteLinkModel> addLink({
    required String noteId,
    required String url,
    String? title,
  });

  Future<void> deleteLink(String id);
}

/// Implements note operations using the injected Supabase client.
final class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  const NoteRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('A signed-in user is required for note operations.');
    }
    return userId;
  }

  @override
  Future<List<NoteModel>> getNotes({
    String? searchQuery,
    String? courseId,
  }) async {
    var query = _client
        .from('notes')
        .select(_noteSelect)
        .eq('is_deleted', false);
    if (courseId != null) {
      query = query.eq('course_id', courseId);
    }
    final trimmedSearch = searchQuery?.trim() ?? '';
    if (trimmedSearch.isNotEmpty) {
      final pattern = '%$trimmedSearch%';
      query = query.or('title.ilike.$pattern,content_plain.ilike.$pattern');
    }
    final rows = await query.order('updated_at', ascending: false);
    return rows.map(NoteModel.fromJson).toList(growable: false);
  }

  @override
  Future<NoteModel> createNote({
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    final row = await _client
        .from('notes')
        .insert({
          'user_id': _userId,
          'title': title,
          'content': content,
          'content_plain': contentPlain,
          'course_id': courseId,
        })
        .select(_noteSelect)
        .single();
    return NoteModel.fromJson(row);
  }

  @override
  Future<NoteModel> updateNote({
    required String id,
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    final row = await _client
        .from('notes')
        .update({
          'title': title,
          'content': content,
          'content_plain': contentPlain,
          'course_id': courseId,
        })
        .eq('id', id)
        .select(_noteSelect)
        .single();
    return NoteModel.fromJson(row);
  }

  @override
  Future<void> softDeleteNote(String id) async {
    await _client.from('notes').update({'is_deleted': true}).eq('id', id);
  }

  @override
  Future<NoteLinkModel> addLink({
    required String noteId,
    required String url,
    String? title,
  }) async {
    final row = await _client
        .from('note_links')
        .insert({
          'note_id': noteId,
          'url': url,
          'title': title,
          'link_type': NoteLinkType.fromUrl(url).dbValue,
        })
        .select()
        .single();
    return NoteLinkModel.fromJson(row);
  }

  @override
  Future<void> deleteLink(String id) async {
    await _client.from('note_links').delete().eq('id', id);
  }
}
