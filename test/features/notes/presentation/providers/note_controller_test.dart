import 'package:campusmate/features/notes/domain/entities/note_entity.dart';
import 'package:campusmate/features/notes/domain/repositories/note_repository.dart';
import 'package:campusmate/features/notes/presentation/providers/note_provider.dart';
import 'package:campusmate/features/notes/presentation/providers/note_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late MockNoteRepository repository;
  late ProviderContainer container;

  const note = NoteEntity(
    id: 'note-1',
    title: 'Ringkasan bab 1',
    contentPlain: 'Halo',
  );

  setUp(() {
    repository = MockNoteRepository();
    container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('loadNotes exposes the loaded list', () async {
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => [note]);

    await container.read(noteControllerProvider.notifier).loadNotes();

    expect(
      container.read(noteControllerProvider),
      const NoteState.loaded([note]),
    );
  });

  test('loadNotes surfaces a safe failure message', () async {
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenThrow(StateError('no session'));

    await container.read(noteControllerProvider.notifier).loadNotes();

    final state = container.read(noteControllerProvider);
    expect(state.status, NoteListStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('search forwards the query to the repository', () async {
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => [note]);

    await container.read(noteControllerProvider.notifier).search('bab');

    verify(
      () => repository.getNotes(searchQuery: 'bab', courseId: null),
    ).called(1);
    expect(container.read(noteControllerProvider).searchQuery, 'bab');
  });

  test('setCourseFilter reloads with the course id', () async {
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => [note]);

    await container
        .read(noteControllerProvider.notifier)
        .setCourseFilter('course-1');

    verify(
      () => repository.getNotes(searchQuery: '', courseId: 'course-1'),
    ).called(1);
  });

  test('createNote returns the new id and reloads', () async {
    when(
      () => repository.createNote(
        title: any(named: 'title'),
        content: any(named: 'content'),
        contentPlain: any(named: 'contentPlain'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => note);
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => [note]);

    final id = await container
        .read(noteControllerProvider.notifier)
        .createNote(title: 'Ringkasan bab 1');

    expect(id, 'note-1');
    expect(container.read(noteControllerProvider).notes, [note]);
  });

  test('createNote failure keeps previous notes', () async {
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => [note]);
    await container.read(noteControllerProvider.notifier).loadNotes();

    when(
      () => repository.createNote(
        title: any(named: 'title'),
        content: any(named: 'content'),
        contentPlain: any(named: 'contentPlain'),
        courseId: any(named: 'courseId'),
      ),
    ).thenThrow(const FormatException('bad data'));

    final id = await container
        .read(noteControllerProvider.notifier)
        .createNote(title: 'X');

    final state = container.read(noteControllerProvider);
    expect(id, isNull);
    expect(state.status, NoteListStatus.failure);
    expect(state.notes, [note]);
    expect(state.errorMessage, 'Data catatan tidak valid.');
  });

  test('deleteNote reloads and returns true', () async {
    when(() => repository.deleteNote('note-1')).thenAnswer((_) async {});
    when(
      () => repository.getNotes(
        searchQuery: any(named: 'searchQuery'),
        courseId: any(named: 'courseId'),
      ),
    ).thenAnswer((_) async => const []);

    final deleted = await container
        .read(noteControllerProvider.notifier)
        .deleteNote('note-1');

    expect(deleted, isTrue);
    expect(container.read(noteControllerProvider).notes, isEmpty);
  });
}
