import 'record.dart';

/// Support [Function] message.
typedef String StringCallback();

/// Format log message.
abstract class Formatter {
  List<String> format(Record record);

  /// Refer from [DateTime].
  String fmtTime(DateTime dateTime) {
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
