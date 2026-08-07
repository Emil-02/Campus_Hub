import 'package:equatable/equatable.dart';

enum CapturedItemKind { task, event }

/// One task/event candidate concluded by AI from a chat or photo.
class CapturedItemEntity extends Equatable {
  const CapturedItemEntity({
    required this.kind,
    required this.title,
    this.description,
    this.date,
    this.time,
    this.courseName,
  });

  final CapturedItemKind kind;
  final String title;
  final String? description;

  /// Date part of the deadline/event (local).
  final DateTime? date;

  /// Optional time in `HH:mm`.
  final String? time;

  /// Course name as matched by AI against the user's course list.
  final String? courseName;

  @override
  List<Object?> get props => [kind, title, description, date, time, courseName];
}
