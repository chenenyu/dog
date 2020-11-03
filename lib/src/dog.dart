import 'console_emitter.dart';
import 'emitter.dart';
import 'formatter.dart';
import 'level.dart';
import 'pretty_formatter.dart';
import 'record.dart';

/// Dart log.
class Dog {
  static Level level = Level.ALL;

  Dog({
    Formatter formatter,
    Emitter emitter,
  })  : _formatter = formatter ?? PrettyFormatter(),
        _emitter = emitter ?? ConsoleEmitter();

  final Formatter _formatter;
  final Emitter _emitter;

  /// Default to [Level.DEBUG].
  void call(dynamic message, {String tag, StackTrace stackTrace}) =>
      d(message, tag: tag, stackTrace: stackTrace);

  void v(dynamic message, {String tag, StackTrace stackTrace}) {
    _log(Level.VERBOSE, message, tag: tag, stackTrace: stackTrace);
  }

  void d(dynamic message, {String tag, StackTrace stackTrace}) {
    _log(Level.DEBUG, message, tag: tag, stackTrace: stackTrace);
  }

  void i(dynamic message, {String tag, StackTrace stackTrace}) {
    _log(Level.INFO, message, tag: tag, stackTrace: stackTrace);
  }

  void w(dynamic message, {String tag, StackTrace stackTrace}) {
    _log(Level.WARNING, message, tag: tag, stackTrace: stackTrace);
  }

  void e(dynamic message, {String tag, StackTrace stackTrace}) {
    _log(Level.ERROR, message, tag: tag, stackTrace: stackTrace);
  }

  void _log(
    Level level,
    dynamic message, {
    String tag,
    StackTrace stackTrace,
  }) {
    if (level < Dog.level) {
      return;
    }
    Record record = Record(level, message, tag, DateTime.now(), stackTrace);
    List<String> lines = _formatter.format(record);
    _emitter.emit(level, lines);
  }
}
