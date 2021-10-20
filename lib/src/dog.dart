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
  Level level = Level.all;

  final Set<Handler> _handlers = {};

  Dog({Handler? handler}) {
    if (handler != null) {
      _handlers.add(handler);
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
    if (level < this.level) {
      return;
    }
    Record record =
        Record(level, message, DateTime.now(), tag, title, stackTrace);
    for (Handler handler in _handlers) {
      handler.handle(record);
    }
  }

  void registerHandler(Handler handler) {
    _handlers.add(handler);
  }

  void unregisterHandler(Handler handler) {
    _handlers.remove(handler);
  }

  void destroy() {
    for (Handler handler in _handlers) {
      handler.destroy();
    }
    _handlers.clear();
  }
}
