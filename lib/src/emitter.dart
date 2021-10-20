import 'package:dog/src/record.dart';

/// Emit log.
abstract class Emitter {
  void emit(Record record, List<String> lines);

  void destroy() {}
}
