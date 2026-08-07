import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/network/supabase_provider.dart';
import '../../data/datasources/note_remote_data_source.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/repositories/note_repository.dart';
import 'note_state.dart';

/// Provides the remote note datasource from the existing client.
final noteRemoteDataSourceProvider = Provider<NoteRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase is not initialized; note data is unavailable.');
  }
  return NoteRemoteDataSourceImpl(client);
});

/// Provides the domain note repository implementation.
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(ref.watch(noteRemoteDataSourceProvider));
});

/// Provides the note controller and its current state.
final noteControllerProvider = NotifierProvider<NoteController, NoteState>(
  NoteController.new,
);

/// Coordinates note CRUD/search and exposes their state.
final class NoteController extends Notifier<NoteState> {
  NoteRepository get _repository => ref.read(noteRepositoryProvider);

  @override
  NoteState build() => const NoteState.initial();

  /// Loads notes for the active search/course filter.
  Future<void> loadNotes() async {
    state = NoteState.loading(
      searchQuery: state.searchQuery,
      courseIdFilter: state.courseIdFilter,
    );
    try {
      final notes = await _repository.getNotes(
        searchQuery: state.searchQuery,
        courseId: state.courseIdFilter,
      );
      state = NoteState.loaded(
        notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
    }
  }

  /// NOTE-02: server-side search on title/content.
  Future<void> search(String query) async {
    state = NoteState.loaded(
      state.notes,
      searchQuery: query,
      courseIdFilter: state.courseIdFilter,
      isMutating: state.isMutating,
    );
    await loadNotes();
  }

  /// Narrows the list to one course (null clears it).
  Future<void> setCourseFilter(String? courseId) async {
    state = NoteState.loaded(
      state.notes,
      searchQuery: state.searchQuery,
      courseIdFilter: courseId,
      isMutating: state.isMutating,
    );
    await loadNotes();
  }

  /// Creates a note and returns its id, or null on failure.
  Future<String?> createNote({
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    try {
      final note = await _repository.createNote(
        title: title,
        content: content,
        contentPlain: contentPlain,
        courseId: courseId,
      );
      await loadNotes();
      return note.id;
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
      return null;
    }
  }

  /// Saves note fields. Returns true when stored.
  Future<bool> updateNote({
    required String id,
    required String title,
    String? content,
    String? contentPlain,
    String? courseId,
  }) async {
    try {
      await _repository.updateNote(
        id: id,
        title: title,
        content: content,
        contentPlain: contentPlain,
        courseId: courseId,
      );
      await loadNotes();
      return true;
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
      return false;
    }
  }

  /// Soft-deletes a note. Returns true when removed.
  Future<bool> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
      return true;
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
      return false;
    }
  }

  /// NOTE-06: attaches a validated URL. Returns true when stored.
  Future<bool> addLink({
    required String noteId,
    required String url,
    String? title,
  }) async {
    try {
      await _repository.addLink(noteId: noteId, url: url, title: title);
      await loadNotes();
      return true;
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
      return false;
    }
  }

  /// Removes an attached link.
  Future<bool> deleteLink(String id) async {
    try {
      await _repository.deleteLink(id);
      await loadNotes();
      return true;
    } catch (error) {
      state = NoteState.failure(
        _safeErrorMessage(error),
        notes: state.notes,
        searchQuery: state.searchQuery,
        courseIdFilter: state.courseIdFilter,
      );
      return false;
    }
  }

  String _safeErrorMessage(Object error) {
    debugPrint('Note error: $error');
    if (error is PostgrestException) {
      return 'Gagal menyimpan ke server. Coba lagi.';
    }
    if (error is SocketException || error is TimeoutException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (error is StateError) {
      return 'Sesi tidak valid. Silakan login ulang.';
    }
    if (error is FormatException) {
      return 'Data catatan tidak valid.';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
