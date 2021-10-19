import 'package:ansicolor/ansicolor.dart';
import 'package:dog/src/emitter.dart';
import 'package:dog/src/level.dart';
import 'package:dog/src/record.dart';

/// Print to console.
class ConsoleEmitter extends Emitter {
  final Map levelColors = {
    Level.verbose: 008, // gray
    Level.debug: 006, // cyan
    Level.info: 007, // white
    Level.warning: 003, // yellow
    Level.error: 001, // red
  };

  final AnsiPen pen = AnsiPen();

  ConsoleEmitter({bool? supportsAnsiColor}) {
    if (supportsAnsiColor != null) {
      ansiColorDisabled = !supportsAnsiColor;
    }
  }

  @override
  void emit(Record record, List<String> lines) {
    pen.reset();
    if (levelColors[record.level] != null) {
      pen.xterm(levelColors[record.level]);
    }
    for (String line in lines) {
      print(pen(line));
    }
  }
}
