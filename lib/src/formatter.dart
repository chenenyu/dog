import 'dart:convert';
import 'dart:math';

import 'package:stack_trace/stack_trace.dart';

import 'record.dart';

/// Support [Function] message.
typedef String StringCallback();

const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

/// Format log message.
class Formatter {
  static const String topLeftCorner = '┌';
  static const String middleCorner = '├';
  static const String bottomLeftCorner = '└';
  static const String solidDivider = '─';
  static const String dottedDivider = '┄';
  static const String verticalLine = '│';

  static const int lineLength = 120;

  String _topBorder;
  String _middleBorder;
  String _bottomBorder;

  /// ┌───────────
  String get topBorder {
    if (_topBorder == null) {
      List<String> l = List(lineLength);
      l[0] = topLeftCorner;
      l.fillRange(1, lineLength, solidDivider);
      _topBorder = l.join();
    }
    return _topBorder;
  }

  /// ├┄┄┄┄┄┄┄┄┄┄┄
  String get middleBorder {
    if (_middleBorder == null) {
      List<String> l = List(lineLength);
      l[0] = middleCorner;
      l.fillRange(1, lineLength, dottedDivider);
      _middleBorder = l.join();
    }
    return _middleBorder;
  }

  /// └───────────
  String get bottomBorder {
    if (_bottomBorder == null) {
      List<String> l = List(lineLength);
      l[0] = bottomLeftCorner;
      l.fillRange(1, lineLength, solidDivider);
      _bottomBorder = l.join();
    }
    return _bottomBorder;
  }

  List<String> format(Record record) {
    String msg = _convertMessage(record.message);
    String st;
    if (record.stackTrace != null) {
      st = _convertStackTrace(record.stackTrace);
    }

    List<String> lines = [];
    lines.add(topBorder);
    // level time caller
    String caller = _getCaller();
    lines.add(
        '$verticalLine ${record.level.name} ${_fmtTime(record.dateTime)}${caller == null ? '' : (' (' + caller + ')')}');
    lines.add(middleBorder);
    // message
    for (String line in msg.split('\n')) {
      lines.add('$verticalLine $line');
    }
    if (st != null) {
      lines.add(middleBorder);
      // stack trace
      for (String line in st.split('\n')) {
        lines.add('$verticalLine $line');
      }
    }
    lines.add(bottomBorder);

    return lines;
  }

  String _convertMessage(dynamic message) {
    String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is Iterable) {
      msg = _jsonEncoder.convert(message);
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

  /// 10 lines at most.
  String _convertStackTrace(StackTrace stackTrace) {
    String st = stackTrace.toString();
    List<String> lines = st.split('\n');
    int length = lines.length;
    st = length <= 10 ? st : lines.sublist(0, min(length, 10)).join('\n');
    if (st.endsWith('\n')) {
      st = st.substring(0, st.length - 2); // rm the last empty line.
    }
    return st;
  }

  /// Refer from [DateTime].
  String _fmtTime(DateTime dateTime) {
    String _threeDigits(int n) {
      if (n >= 100) return '$n';
      if (n >= 10) return '0$n';
      return '00$n';
    }

    String _twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    String h = _twoDigits(dateTime.hour);
    String min = _twoDigits(dateTime.minute);
    String sec = _twoDigits(dateTime.second);
    String ms = _threeDigits(dateTime.millisecond);
    return '$h:$min:$sec.$ms';
  }

  String _getCaller() {
    // print(StackTrace.current);
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
}
