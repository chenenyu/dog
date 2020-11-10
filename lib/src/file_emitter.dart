import 'dart:io';

import 'emitter.dart';
import 'record.dart';

/// Write log to file.
class FileEmitter extends Emitter {
  /// The file to store log.
  final File file;

  /// [FileMode.writeOnlyAppend] or [FileMode.writeOnly].
  final bool append;

  IOSink _ioSink;

  FileEmitter({
    this.file,
    this.append,
  }) : assert(file != null) {
    _ioSink = file.openWrite(
        mode: append ?? true ? FileMode.writeOnlyAppend : FileMode.writeOnly);
  }

  @override
  void emit(Record record, List<String> lines) {
    lines.forEach(_ioSink?.writeln);
  }

  @override
  void destroy() async {
    await _ioSink?.flush();
    await _ioSink?.close();
  }
}
