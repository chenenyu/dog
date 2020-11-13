import 'dart:html';

import '../emitter.dart';
import '../level.dart';
import '../record.dart';

/// Print to browser console.
class ConsoleEmitter extends Emitter {
  void emit(Record record, List<String> lines) {
    String output = lines.join('\n');
    var log = window.console.log;
    if (record.level == Level.VERBOSE) {
      log = window.console.debug;
    } else if (record.level == Level.DEBUG) {
      log = window.console.debug;
    } else if (record.level == Level.INFO) {
      log = window.console.info;
    } else if (record.level == Level.WARNING) {
      output = '\n' + output; // chrome
      log = window.console.warn;
    } else if (record.level == Level.ERROR) {
      output = '\n' + output; // chrome
      log = window.console.error;
    }

    log(output);
  }
}
