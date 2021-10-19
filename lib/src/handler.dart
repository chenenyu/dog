import 'dart:async';

import 'package:dog/src/emitter.dart';
import 'package:dog/src/formatter.dart';
import 'package:dog/src/record.dart';

/// Log handler.
class Handler {
  final Formatter formatter;
  final Emitter emitter;

  StreamSubscription? _ss;

  Handler({
    required this.formatter,
    required this.emitter,
  });

  void subscribe(Stream<Record> stream) {
    _ss ??= stream.listen((Record record) {
      List<String> lines = formatter.format(record);
      emitter.emit(record, lines);
    });
  }

  Future<void> destroy() async {
    await _ss?.cancel();
    _ss = null;
    emitter.destroy();
  }
}
