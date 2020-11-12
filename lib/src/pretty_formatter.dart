import 'dart:convert';
import 'dart:math';

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
    this.stackTraceLevel = 10,
    this.callerGetter = callerInfo,
  });

  /// If the pretty message lines exceed [maxPrettyLines],
  /// then back to normal message style.
  final int maxPrettyLines;

  /// Each message line length.
  final int lineLength;

  /// The level we will retrieve from StackTrace.
  final int stackTraceLevel;

  /// Function to get caller info.
  final StringCallback callerGetter;

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
    List<String> lines = [];

    lines.add(topBorder);

    // tag/level time caller
    String caller = callerGetter == null ? null : callerGetter();
    lines.add('$verticalLine ${record.tag ?? record.level.name}'
        ' ${_fmtTime(record.dateTime)}'
        '${caller == null ? '' : (' (' + caller + ')')}');

    lines.add(middleBorder);

    // title
    if (record.title != null) {
      lines.add('$verticalLine ${record.title}');
      lines.add(middleBorder);
    }

    // message
    String msg = _convertMessage(record.message);
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
    String st;
    if (record.stackTrace != null) {
      st = _convertStackTrace(record.stackTrace);
    }
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
}
