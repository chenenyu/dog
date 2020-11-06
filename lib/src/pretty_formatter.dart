import 'dart:convert';
import 'dart:math';

import 'package:stack_trace/stack_trace.dart';

import 'formatter.dart';
import 'record.dart';

/// Format log message.
class PrettyFormatter extends Formatter {
  static const String topLeftCorner = '┌';
  static const String middleCorner = '├';
  static const String bottomLeftCorner = '└';
  static const String solidDivider = '─';
  static const String dottedDivider = '┄';
  static const String verticalLine = '│';

  PrettyFormatter({
    this.maxPrettyLines = 20,
    this.lineLength = 120,
  });

  /// If the pretty message lines exceed [maxPrettyLines],
  /// then back to normal message style.
  final int maxPrettyLines;

  /// Each message line length.
  final int lineLength;

  final JsonEncoder prettyJsonEncoder = JsonEncoder.withIndent('  ');

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

  @override
  List<String> format(Record record) {
    String msg = _convertMessage(record.message);
    String st;
    if (record.stackTrace != null) {
      st = _convertStackTrace(record.stackTrace);
    }

    List<String> lines = [];
    lines.add(topBorder);
    // tag/level time caller
    String caller = _getCaller();
    lines.add('$verticalLine ${record.tag ?? record.level.name}'
        ' ${fmtTime(record.dateTime)}'
        '${caller == null ? '' : (' (' + caller + ')')}');
    lines.add(middleBorder);
    if (record.title != null) {
      lines.add('$verticalLine ${record.title}');
      lines.add(middleBorder);
    }
    // message
    for (String line in msg.split('\n')) {
      if (line.length > lineLength - 2) {
        RuneIterator iterator = line.runes.iterator;
        int count = 0, p = 0;
        while (iterator.moveNext()) {
          count += iterator.currentSize;
          if (count >= lineLength - 2) {
            int end = iterator.rawIndex + iterator.currentSize;
            lines.add('$verticalLine ${line.substring(p, end)}');
            p = end;
            count = 0;
          }
        }
        if (p < line.length) {
          lines.add('$verticalLine ${line.substring(p)}');
        }
      } else {
        lines.add('$verticalLine $line');
      }
    }
    // stack trace
    if (st != null) {
      lines.add(middleBorder);
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
      msg = prettyJsonEncoder.convert(message);
      if (msg.split('\n').length > maxPrettyLines) {
        msg = jsonEncode(message);
      }
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
