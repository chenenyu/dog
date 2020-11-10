import 'dart:convert';
import 'dart:math';

import 'package:stack_trace/stack_trace.dart';

import 'formatter.dart';
import 'record.dart';

/// This formatter will not generate borders.
class SimpleFormatter extends Formatter {
  /// The level we will retrieve from StackTrace.
  final int stackTraceLevel;

  SimpleFormatter({this.stackTraceLevel = 10});

  @override
  List<String> format(Record record) {
    List<String> lines = [];
    // time tag/level caller
    String caller = _getCaller();
    lines.add('${record.dateTime.toIso8601String()}'
        ' ${record.tag ?? record.level.name}'
        '${caller == null ? '' : (' (' + caller + ')')}');
    // title
    if (record.title != null) {
      lines.add(record.title);
    }
    // message
    String msg = _convertMessage(record.message);
    lines.add(msg);
    // stack trace
    if (record.stackTrace != null) {
      String st = _convertStackTrace(record.stackTrace);
      lines.add(st);
    }
    // Add a empty line to separate log. Don't use `\n`, it'll cause two empty lines.
    lines.add('');
    return lines;
  }

  String _getCaller() {
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

  String _convertMessage(dynamic message) {
    String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is Iterable) {
      msg = jsonEncode(message);
    } else if (message is StringCallback) {
      msg = message().toString();
    } else if (message is Exception) {
      msg = message.toString();
    } else if (message is StackTrace) {
      msg = _convertStackTrace(message);
    } else {
      msg = message.toString();
    }
    return msg;
  }

  /// [stackTraceLevel] lines at most.
  String _convertStackTrace(StackTrace stackTrace) {
    String st = stackTrace.toString();
    List<String> lines = st.split('\n');
    int length = lines.length;
    st = length <= stackTraceLevel
        ? st
        : lines.sublist(0, min(length, stackTraceLevel)).join('\n');
    if (st.endsWith('\n')) {
      st = st.substring(0, st.length - 2); // rm the last empty line.
    }
    return st;
  }
}
