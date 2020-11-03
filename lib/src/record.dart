import 'level.dart';

/// Log record.
class Record {
  final Level level;
  final dynamic message;
  final String tag;
  final DateTime dateTime;
  final StackTrace stackTrace;

  Record(
    this.level,
    this.message,
    this.tag,
    this.dateTime,
    this.stackTrace,
  );
}
