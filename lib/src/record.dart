import 'level.dart';

/// Log record.
class Record {
  final Level level;
  final dynamic message;
  /// Optional. Defaults to level name.
  final String tag;
  final DateTime dateTime;

  /// Optional.
  final StackTrace stackTrace;

  Record(
    this.level,
    this.message,
    this.tag,
    this.dateTime,
    this.stackTrace,
  );
}
