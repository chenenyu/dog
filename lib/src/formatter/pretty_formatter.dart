import 'dart:convert';
import 'dart:math';

import 'package:dog/src/formatter.dart';
import 'package:dog/src/record.dart';
import 'package:dog/src/util/char_width.dart';
import 'package:dog/src/util/utils.dart';

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
    this.callerGetter = DogUtils.defaultCallerInfo,
  });

  /// If the pretty message lines exceed [maxPrettyLines],
  /// then back to normal message style.
  final int maxPrettyLines;

  /// Each message line length.
  final int lineLength;

  /// The level we will retrieve from StackTrace.
  final int stackTraceLevel;

  /// Function to get caller info.
  final MessageCallback? callerGetter;

  final JsonEncoder prettyJsonEncoder = JsonEncoder.withIndent('  ');

  String? _topBorder;
  String? _middleBorder;
  String? _bottomBorder;

  /// ┌───────────
  String get topBorder {
    if (_topBorder == null) {
      List<String> l = List.generate(
          lineLength, (index) => index == 0 ? topLeftCorner : solidDivider,
          growable: false);
      _topBorder = l.join();
    }
    return _topBorder!;
  }

  /// ├┄┄┄┄┄┄┄┄┄┄┄
  String get middleBorder {
    if (_middleBorder == null) {
      List<String> l = List.generate(
          lineLength, (index) => index == 0 ? middleCorner : dottedDivider,
          growable: false);
      _middleBorder = l.join();
    }
    return _middleBorder!;
  }

  /// └───────────
  String get bottomBorder {
    if (_bottomBorder == null) {
      List<String> l = List.generate(
          lineLength, (index) => index == 0 ? bottomLeftCorner : solidDivider,
          growable: false);
      _bottomBorder = l.join();
    }
    return _bottomBorder!;
  }

  @override
  List<String> format(Record record) {
    List<String> lines = [];

    lines.add(topBorder);

    // tag/level time caller
    String? caller = callerGetter?.call().toString();
    lines.add('$verticalLine ${DogUtils.fmtTime(record.dateTime)}'
        ' ${record.tag ?? record.level.name}'
        '${caller == null ? '' : (' (' + caller + ')')}');

    lines.add(middleBorder);

    // title
    if (record.title != null) {
      lines.add('$verticalLine ${record.title}');
      lines.add(middleBorder);
    }

    // message
    final int maxWidth = lineLength - 2;
    String msg = convertMessage(record.message);
    for (String line in msg.split('\n')) {
      if (line.length > maxWidth ~/ 2) {
        RuneIterator iterator = line.runes.iterator;
        int widths = 0, p = 0;
        while (iterator.moveNext()) {
          int width = charWidth(iterator.current);
          widths += width;
          if (widths >= maxWidth) {
            if (widths > maxWidth) {
              iterator.movePrevious();
            }
            int end = iterator.rawIndex + iterator.currentSize;
            lines.add('$verticalLine ${line.substring(p, end)}');
            p = end;
            widths = 0;
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
    String? st;
    if (record.stackTrace != null) {
      st = convertStackTrace(record.stackTrace!);
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

  String convertMessage(dynamic message) {
    String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is Iterable) {
      try {
        msg = prettyJsonEncoder.convert(message);
        if (msg.split('\n').length > maxPrettyLines) {
          msg = jsonEncode(message);
        }
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
