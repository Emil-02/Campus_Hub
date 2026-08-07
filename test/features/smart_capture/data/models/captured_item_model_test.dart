import 'package:campusmate/features/smart_capture/data/models/captured_item_model.dart';
import 'package:campusmate/features/smart_capture/domain/entities/captured_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a complete task row', () {
    final item = CapturedItemModel.fromJson({
      'jenis': 'task',
      'judul': ' Laporan  Analisis UI ',
      'deskripsi': 'Kumpul lewat LMS',
      'tanggal': '2026-08-14',
      'jam': '23.59',
      'mata_kuliah': 'INTERAKSI MANUSIA DAN KOMPUTER',
    });

    expect(item, isNotNull);
    expect(item!.kind, CapturedItemKind.task);
    expect(item.title, 'Laporan Analisis UI');
    expect(item.description, 'Kumpul lewat LMS');
    expect(item.date, DateTime(2026, 8, 14));
    expect(item.time, '23:59');
    expect(item.courseName, 'INTERAKSI MANUSIA DAN KOMPUTER');
  });

  test('parses an event row and defaults unknown kind to task', () {
    final event = CapturedItemModel.fromJson({
      'jenis': 'EVENT',
      'judul': 'Seminar Proposal',
      'tanggal': '2026-09-01',
    });
    expect(event!.kind, CapturedItemKind.event);
    expect(event.time, isNull);

    final unknown = CapturedItemModel.fromJson({
      'jenis': 'lainnya',
      'judul': 'Kuis take home',
    });
    expect(unknown!.kind, CapturedItemKind.task);
  });

  test('returns null without a title', () {
    expect(CapturedItemModel.fromJson({'jenis': 'task'}), isNull);
    expect(CapturedItemModel.fromJson({'judul': '  '}), isNull);
  });

  test('invalid date or time becomes null', () {
    final item = CapturedItemModel.fromJson({
      'judul': 'Tugas tanpa jadwal jelas',
      'tanggal': 'Jumat depan',
      'jam': 'malam',
    });
    expect(item!.date, isNull);
    expect(item.time, isNull);
  });
}
