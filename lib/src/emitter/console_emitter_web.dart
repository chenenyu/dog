import 'dart:html';
import 'dart:js';

import '../emitter.dart';
import '../level.dart';
import '../record.dart';

/// Print to browser console.
class ConsoleEmitter extends Emitter {
  @override
  void emit(Record record, List<String> lines) {
    String output = lines.join('\n');
    if (record.level == Level.VERBOSE) {
      jsConsole('debug', ['%c$output', 'color:grey']);
    } else if (record.level == Level.DEBUG) {
      jsConsole('debug', ['%c$output', 'color:#00758F']); // MosaicBlue
    } else if (record.level == Level.INFO) {
      window.console.info(output);
    } else if (record.level == Level.WARNING) {
      output = '\n' + output; // chrome
      window.console.warn(output);
    } else if (record.level == Level.ERROR) {
      output = '\n' + output; // chrome
      window.console.error(output);
    } else {
      window.console.log(output);
    }
  }

  void jsConsole(String method, [List args]) {
    JsObject console = JsObject.fromBrowserObject(context['console']);
    if (console != null && console.hasProperty(method)) {
      console.callMethod(method, args);
    }
  }
}
