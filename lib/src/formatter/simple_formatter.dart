import 'dart:convert';
import 'dart:math';

import 'package:dog/src/formatter.dart';
import 'package:dog/src/record.dart';
import 'package:dog/src/util/utils.dart';

/// This formatter will not generate borders.
class SimpleFormatter extends Formatter {
  /// The level we will retrieve from StackTrace.
  final int stackTraceLevel;

  /// Function to get caller info.
  final MessageCallback? callerGetter;

  SimpleFormatter({
    this.stackTraceLevel = 10,
    this.callerGetter = DogUtils.defaultCallerInfo,
  });

  @override
  List<String> format(Record record) {
    List<String> lines = [];
    // tag/level time caller
    String? caller = callerGetter?.call().toString();
    lines.add('${record.tag ?? record.level.name}'
        ' ${record.dateTime.toIso8601String()}'
        '${caller == null ? '' : (' (' + caller + ')')}');
    // title
    if (record.title != null) {
      lines.add(record.title!);
    }
    // message
    String msg = convertMessage(record.message);
    lines.add(msg);
    // stack trace
    if (record.stackTrace != null) {
      String st = convertStackTrace(record.stackTrace!);
      lines.add(st);
    }
    return lines;
  }

  String convertMessage(dynamic message) {
    String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is Iterable) {
      try {
        msg = jsonEncode(message);
      } catch (e) {
        // JsonUnsupportedObjectError
        msg = message.toString();
      }
    } else if (message is MessageCallback) {
      msg = message().toString();
    } else if (message is Exception) {
      msg = message.toString();
    } else if (message is StackTrace) {
      msg = convertStackTrace(message);
    } else {
      msg = message.toString();
    }
    return msg;
  }

  /// [stackTraceLevel] lines at most.
  String convertStackTrace(StackTrace stackTrace) {
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
