import 'package:dog/src/dispatcher.dart';
import 'package:dog/src/emitter/console_emitter.dart';
import 'package:dog/src/formatter/pretty_formatter.dart';
import 'package:dog/src/handler.dart';
import 'package:dog/src/level.dart';
import 'package:dog/src/record.dart';

Dog dog = Dog(
    handler: Handler(formatter: PrettyFormatter(), emitter: ConsoleEmitter()));

/// Dart log.
///
/// [message] The message to output.
/// [tag] Optional. Log tag.
/// [title] Optional. Line shows above [message].
/// [stackTrace] Optional. StackTrace shows below [message].
class Dog {
  /// Specify [level] to [Level.off] to disable all output.
  static Level level = Level.all;

  final Dispatcher _dispatcher = Dispatcher();

  Dog({Handler? handler}) {
    if (handler != null) {
      _dispatcher.registerHandler(handler);
    }
  }

  void v(dynamic message,
      {String? tag, String? title, StackTrace? stackTrace}) {
    _log(Level.verbose, message,
        tag: tag, title: title, stackTrace: stackTrace);
  }

  void d(dynamic message,
      {String? tag, String? title, StackTrace? stackTrace}) {
    _log(Level.debug, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void i(dynamic message,
      {String? tag, String? title, StackTrace? stackTrace}) {
    _log(Level.info, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void w(dynamic message,
      {String? tag, String? title, StackTrace? stackTrace}) {
    _log(Level.warning, message,
        tag: tag, title: title, stackTrace: stackTrace);
  }

  void e(dynamic message,
      {String? tag, String? title, StackTrace? stackTrace}) {
    _log(Level.error, message, tag: tag, title: title, stackTrace: stackTrace);
  }

  void _log(
    Level level,
    dynamic message, {
    String? tag,
    String? title,
    StackTrace? stackTrace,
  }) {
    if (level < Dog.level) {
      return;
    }
    Record record =
        Record(level, message, DateTime.now(), tag, title, stackTrace);
    _dispatcher.add(record);
  }

  void registerHandler(Handler handler) {
    _dispatcher.registerHandler(handler);
  }

  void unregisterHandler(Handler handler) {
    _dispatcher.unregisterHandler(handler);
  }

  void destroy() {
    _dispatcher.destroy();
  }
}
