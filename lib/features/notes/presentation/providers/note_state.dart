import 'package:equatable/equatable.dart';

import '../../domain/entities/note_entity.dart';

enum NoteListStatus { initial, loading, loaded, failure }

/// Immutable state for the note list.
class NoteState extends Equatable {
  const NoteState._({
    required this.status,
    this.notes = const [],
    this.searchQuery = '',
    this.courseIdFilter,
    this.errorMessage,
    this.isMutating = false,
  });

  const NoteState.initial() : this._(status: NoteListStatus.initial);

  const NoteState.loading({String searchQuery = '', String? courseIdFilter})
    : this._(
        status: NoteListStatus.loading,
        searchQuery: searchQuery,
        courseIdFilter: courseIdFilter,
      );

  const NoteState.loaded(
    List<NoteEntity> notes, {
    String searchQuery = '',
    String? courseIdFilter,
    bool isMutating = false,
  }) : this._(
         status: NoteListStatus.loaded,
         notes: notes,
         searchQuery: searchQuery,
         courseIdFilter: courseIdFilter,
         isMutating: isMutating,
       );

  const NoteState.failure(
    String message, {
    List<NoteEntity> notes = const [],
    String searchQuery = '',
    String? courseIdFilter,
  }) : this._(
         status: NoteListStatus.failure,
         errorMessage: message,
         notes: notes,
         searchQuery: searchQuery,
         courseIdFilter: courseIdFilter,
       );

  final NoteListStatus status;
  final List<NoteEntity> notes;
  final String searchQuery;
  final String? courseIdFilter;
  final String? errorMessage;

  /// True while a create/update/delete request is in flight.
  final bool isMutating;

  @override
  List<Object?> get props => [
    status,
    notes,
    searchQuery,
    courseIdFilter,
    errorMessage,
    isMutating,
  ];
}
