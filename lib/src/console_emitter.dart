import 'dart:io' as io;

import 'package:ansicolor/ansicolor.dart';

import 'emitter.dart';
import 'level.dart';

/// Print to console.
class ConsoleEmitter extends Emitter {
  ConsoleEmitter() {
    color_disabled = !io.stdout.supportsAnsiEscapes;
  }

  final Map levelColors = {
    Level.VERBOSE: 008, // gray
    Level.DEBUG: 006, // cyan
    Level.INFO: 007, // white
    Level.WARNING: 003, // yellow
    Level.ERROR: 001, // red
  };

  final AnsiPen pen = AnsiPen();

  void emit(Level level, List<String> lines) {
    pen.reset();
    if (levelColors[level] != null) {
      pen.xterm(levelColors[level]);
    }
    for (String line in lines) {
      print(pen(line));
    }
  }
}
