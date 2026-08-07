import '../../domain/entities/imported_course_entity.dart';

/// Parses one course row from the Gemini JSON payload.
final class ImportedCourseModel {
  const ImportedCourseModel._();

  /// Returns null when the row has no usable course name.
  static ImportedCourseEntity? fromJson(Map<String, dynamic> json) {
    final name = _cleanText(json['nama']);
    if (name == null) {
      return null;
    }
    final meetingsJson = json['pertemuan'];
    final meetings = <ImportedMeetingEntity>[
      if (meetingsJson is List)
        for (final item in meetingsJson)
          if (item is Map<String, dynamic>) ?_meetingFromJson(item),
    ];
    return ImportedCourseEntity(
      name: name,
      code: _cleanText(json['kode']),
      credits: _parseInt(json['sks']),
      lecturer: _cleanText(json['dosen']),
      meetings: meetings,
    );
  }

  static ImportedMeetingEntity? _meetingFromJson(Map<String, dynamic> json) {
    final day = _parseInt(json['hari']);
    final start = _parseTime(json['jam_mulai']);
    final end = _parseTime(json['jam_selesai']);
    if (day == null || day < 1 || day > 7 || start == null || end == null) {
      return null;
    }
    if (start.compareTo(end) >= 0) {
      return null;
    }
    return ImportedMeetingEntity(
      dayOfWeek: day,
      startTime: start,
      endTime: end,
      room: _cleanText(json['ruangan']),
    );
  }

  static String? _cleanText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }

  /// Normalizes `H:mm`/`HH.mm` to `HH:mm`; returns null when unreadable.
  static String? _parseTime(Object? value) {
    final text = value?.toString().trim().replaceAll('.', ':');
    if (text == null || text.isEmpty) {
      return null;
    }
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      return null;
    }
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
