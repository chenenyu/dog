import 'dart:io' as io;

import 'package:ansicolor/ansicolor.dart';

import 'emitter.dart';
import 'formatter.dart';
import 'level.dart';
import 'record.dart';

/// Dart log.
class Dog {
  static Level level = Level.ALL;

  Dog() {
    color_disabled = !io.stdout.supportsAnsiEscapes;
  }

  final Formatter _formatter = Formatter();
  final Emitter _emitter = Emitter();

  /// Default to [Level.DEBUG].
  void call(dynamic message, {StackTrace stackTrace}) =>
      d(message, stackTrace: stackTrace);

  void v(dynamic message, {StackTrace stackTrace}) {
    _log(Level.VERBOSE, message, stackTrace: stackTrace);
  }

  void d(dynamic message, {StackTrace stackTrace}) {
    _log(Level.DEBUG, message, stackTrace: stackTrace);
  }

  void i(dynamic message, {StackTrace stackTrace}) {
    _log(Level.INFO, message, stackTrace: stackTrace);
  }

  void w(dynamic message, {StackTrace stackTrace}) {
    _log(Level.WARNING, message, stackTrace: stackTrace);
  }

  void e(dynamic message, {StackTrace stackTrace}) {
    _log(Level.ERROR, message, stackTrace: stackTrace);
  }

  void _log(Level level,
      dynamic message, {
        StackTrace stackTrace,
      }) {
    if (level < Dog.level) {
      return;
    }
    Record record = Record(level, message, DateTime.now(), stackTrace);
    List<String> lines = _formatter.format(record);
    _emitter.emit(level, lines);
  }
}
