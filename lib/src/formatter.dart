import 'record.dart';

/// Format log message.
abstract class Formatter {
  List<String> format(Record record);
}

/// Support [Function] message.
typedef MessageCallback = Object? Function();
