import 'package:dog/src/emitter.dart';
import 'package:dog/src/formatter.dart';
import 'package:dog/src/record.dart';

/// Log handler.
class Handler {
  final Formatter formatter;
  final Emitter emitter;

  Handler({
    required this.formatter,
    required this.emitter,
  });

  void handle(Record record) {
    List<String> lines = formatter.format(record);
    emitter.emit(record, lines);
  }

  void destroy() {
    emitter.destroy();
  }
}
