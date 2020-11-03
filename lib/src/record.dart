import 'level.dart';

/// Log record.
class Record {
  final Level level;
  final dynamic message;
  final DateTime dateTime;

  /// Optional. Defaults to level name.
  final String tag;

  /// Optional.
  final StackTrace stackTrace;

  Record(
    this.level,
    this.message,
    this.dateTime,
    this.tag,
    this.stackTrace,
  );
}
