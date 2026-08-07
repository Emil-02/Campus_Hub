import '../../domain/entities/captured_item_entity.dart';

/// Parses one captured task/event from the Gemini JSON payload.
final class CapturedItemModel {
  const CapturedItemModel._();

  /// Returns null when the row has no usable title.
  static CapturedItemEntity? fromJson(Map<String, dynamic> json) {
    final title = _cleanText(json['judul']);
    if (title == null) {
      return null;
    }
    return CapturedItemEntity(
      kind: json['jenis']?.toString().trim().toLowerCase() == 'event'
          ? CapturedItemKind.event
          : CapturedItemKind.task,
      title: title,
      description: _cleanText(json['deskripsi']),
      date: _parseDate(json['tanggal']),
      time: _parseTime(json['jam']),
      courseName: _cleanText(json['mata_kuliah']),
    );
  }

  static String? _cleanText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? null : text;
  }

  /// Parses `YYYY-MM-DD`; returns null when unreadable.
  static DateTime? _parseDate(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (match == null) {
      return null;
    }
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
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
