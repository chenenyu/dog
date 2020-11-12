import 'package:stack_trace/stack_trace.dart';

import 'record.dart';

/// Format log message.
abstract class Formatter {
  List<String> format(Record record);
}

/// Support [Function] message.
typedef String StringCallback();

/// Default caller info getter.
String callerInfo() {
  List<Frame> frames = Trace.current().frames;
  if (frames != null && frames.isNotEmpty) {
    for (int i = frames.length - 1; i >= 0; i--) {
      if (frames[i].package == 'dog') {
        return frames[i + 1].toString();
      }
    }
  }
  return null;
}
