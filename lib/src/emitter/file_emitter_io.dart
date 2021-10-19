import 'dart:io';

import 'package:dog/src/emitter.dart';
import 'package:dog/src/record.dart';

/// Write log to file.
class FileEmitter extends Emitter {
  /// The file to store log.
  final File file;

  /// [FileMode.writeOnlyAppend] or [FileMode.writeOnly].
  final bool append;

  IOSink? _ioSink;

  FileEmitter({
    required this.file,
    this.append = true,
  }) {
    _ioSink = file.openWrite(
        mode: append ? FileMode.writeOnlyAppend : FileMode.writeOnly);
  }

  @override
  void emit(Record record, List<String> lines) {
    for (String line in lines) {
      _ioSink?.writeln(line);
    }
  }

  @override
  void destroy() async {
    await _ioSink?.flush();
    await _ioSink?.close();
  }
}
