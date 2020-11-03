import 'level.dart';

/// Emit log.
abstract class Emitter {
  void emit(Level level, List<String> lines);
}
