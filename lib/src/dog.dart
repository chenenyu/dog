import 'console_emitter.dart';
import 'emitter.dart';
import 'formatter.dart';
import 'level.dart';
import 'pretty_formatter.dart';
import 'record.dart';

Dog dog = Dog();

/// Dart log.
///
/// [message] The message to output.
/// [tag] Optional. Log tag.
/// [title] Optional. Line shows above [message].
/// [stackTrace] Optional. StackTrace shows below [message].
class Dog {
  /// Specify [level] to [Level.OFF] to disable all output.
  static Level level = Level.ALL;

  Dog({
    Formatter formatter,
    Emitter emitter,
  })  : this.formatter = formatter ?? PrettyFormatter(),
        this.emitter = emitter ?? ConsoleEmitter();

  final Formatter formatter;
  final Emitter emitter;

  /// Default to [Level.DEBUG].
  void call(dynamic message,
          {String tag, String title, StackTrace stackTrace}) =>
      d(message, tag: tag, stackTrace: stackTrace);

  void v(dynamic message, {String tag, String title, StackTrace stackTrace}) {
    _log(Level.VERBOSE, message,
        tag: tag, title: title, stackTrace: stackTrace);
  }

  void d(dynamic message, {String tag, String title, StackTrace stackTrace}) {
    _log(Level.DEBUG, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void i(dynamic message, {String tag, String title, StackTrace stackTrace}) {
    _log(Level.INFO, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void w(dynamic message, {String tag, String title, StackTrace stackTrace}) {
    _log(Level.WARNING, message,
        tag: tag, title: title, stackTrace: stackTrace);
  }

  void e(dynamic message, {String tag, String title, StackTrace stackTrace}) {
    _log(Level.ERROR, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void _log(
    Level level,
    dynamic message, {
    String tag,
    String title,
    StackTrace stackTrace,
  }) {
    if (level < Dog.level) {
      return;
    }
    Record record =
        Record(level, message, DateTime.now(), tag, title, stackTrace);
    List<String> lines = formatter.format(record);
    emitter.emit(record, lines);
  }

  void destroy() {
    emitter.destroy();
  }
}
