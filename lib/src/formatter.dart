import 'record.dart';

/// Support [Function] message.
typedef String StringCallback();

/// Format log message.
abstract class Formatter {
  List<String> format(Record record);
}
