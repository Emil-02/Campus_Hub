import 'package:campusmate/features/courses/domain/entities/course_entity.dart';
import 'package:campusmate/features/courses/domain/repositories/course_repository.dart';
import 'package:campusmate/features/courses/presentation/providers/course_provider.dart';
import 'package:campusmate/features/courses/presentation/providers/course_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCourseRepository extends Mock implements CourseRepository {}

void main() {
  late MockCourseRepository repository;
  late ProviderContainer container;

  const course = CourseEntity(
    id: 'course-1',
    name: 'Struktur Data',
    code: 'IF1234',
    credits: 3,
    lecturer: 'Dr. Budi',
    color: '#4A90D9',
  );

  setUp(() {
    repository = MockCourseRepository();
    container = ProviderContainer(
      overrides: [courseRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('loadCourses exposes the loaded list', () async {
    when(() => repository.getCourses()).thenAnswer((_) async => [course]);

    await container.read(courseControllerProvider.notifier).loadCourses();

    expect(
      container.read(courseControllerProvider),
      const CourseState.loaded([course]),
    );
  });

  test('loadCourses surfaces a safe failure message', () async {
    when(() => repository.getCourses()).thenThrow(StateError('no session'));

    await container.read(courseControllerProvider.notifier).loadCourses();

    final state = container.read(courseControllerProvider);
    expect(state.status, CourseStatus.failure);
    expect(state.errorMessage, 'Sesi tidak valid. Silakan login ulang.');
  });

  test('createCourse reloads the list and returns true', () async {
    when(
      () => repository.createCourse(
        name: any(named: 'name'),
        code: any(named: 'code'),
        credits: any(named: 'credits'),
        lecturer: any(named: 'lecturer'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async => course);
    when(() => repository.getCourses()).thenAnswer((_) async => [course]);

    final saved = await container
        .read(courseControllerProvider.notifier)
        .createCourse(name: 'Struktur Data', color: '#4A90D9');

    expect(saved, isTrue);
    expect(
      container.read(courseControllerProvider),
      const CourseState.loaded([course]),
    );
  });

  test('createCourse keeps previous courses on failure', () async {
    when(() => repository.getCourses()).thenAnswer((_) async => [course]);
    await container.read(courseControllerProvider.notifier).loadCourses();

    when(
      () => repository.createCourse(
        name: any(named: 'name'),
        code: any(named: 'code'),
        credits: any(named: 'credits'),
        lecturer: any(named: 'lecturer'),
        color: any(named: 'color'),
      ),
    ).thenThrow(const FormatException('bad data'));

    final saved = await container
        .read(courseControllerProvider.notifier)
        .createCourse(name: 'Baru', color: '#D94A4A');

    final state = container.read(courseControllerProvider);
    expect(saved, isFalse);
    expect(state.status, CourseStatus.failure);
    expect(state.courses, [course]);
    expect(state.errorMessage, 'Data mata kuliah tidak valid.');
  });

  test('updateCourse reloads the list and returns true', () async {
    when(
      () => repository.updateCourse(
        id: any(named: 'id'),
        name: any(named: 'name'),
        code: any(named: 'code'),
        credits: any(named: 'credits'),
        lecturer: any(named: 'lecturer'),
        color: any(named: 'color'),
      ),
    ).thenAnswer((_) async => course);
    when(() => repository.getCourses()).thenAnswer((_) async => [course]);

    final saved = await container
        .read(courseControllerProvider.notifier)
        .updateCourse(id: 'course-1', name: 'Struktur Data', color: '#4A90D9');

    expect(saved, isTrue);
    expect(
      container.read(courseControllerProvider),
      const CourseState.loaded([course]),
    );
  });

  test('deleteCourse reloads the list and returns true', () async {
    when(() => repository.deleteCourse('course-1')).thenAnswer((_) async {});
    when(() => repository.getCourses()).thenAnswer((_) async => const []);

    final deleted = await container
        .read(courseControllerProvider.notifier)
        .deleteCourse('course-1');

    expect(deleted, isTrue);
    expect(
      container.read(courseControllerProvider),
      const CourseState.loaded([]),
    );
  });

  test('deleteCourse keeps previous courses on failure', () async {
    when(() => repository.getCourses()).thenAnswer((_) async => [course]);
    await container.read(courseControllerProvider.notifier).loadCourses();

    when(
      () => repository.deleteCourse('course-1'),
    ).thenThrow(StateError('no session'));

    final deleted = await container
        .read(courseControllerProvider.notifier)
        .deleteCourse('course-1');

    final state = container.read(courseControllerProvider);
    expect(deleted, isFalse);
    expect(state.status, CourseStatus.failure);
    expect(state.courses, [course]);
  });
}
