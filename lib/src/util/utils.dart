import 'dart:math';

import 'package:stack_trace/stack_trace.dart';

class DogUtils {
  static String _threeDigits(int n) {
    if (n >= 100) return '$n';
    if (n >= 10) return '0$n';
    return '00$n';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }

  /// Refer from [DateTime].
  static String fmtTime(DateTime dateTime) {
    String h = _twoDigits(dateTime.hour);
    String min = _twoDigits(dateTime.minute);
    String sec = _twoDigits(dateTime.second);
    String ms = _threeDigits(dateTime.millisecond);
    return '$h:$min:$sec.$ms';
  }

  /// Default caller info getter.
  static Object? defaultCallerInfo() {
    List<Frame> frames = Trace.current().frames;
    if (frames.isNotEmpty) {
      for (int i = frames.length - 1; i >= 0; i--) {
        if (frames[i].package == 'dog') {
          return frames[min<int>(i + 1, frames.length - 1)].toString();
        }
      }
    }
    return null;
  }
}
