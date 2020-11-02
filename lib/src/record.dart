import 'level.dart';

/// Log record.
class Record {
  final Level level;
  final dynamic message;
  final DateTime dateTime;
  final StackTrace stackTrace;

  Record(this.level, this.message, this.dateTime, this.stackTrace);
}
