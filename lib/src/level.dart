/// If you define your own level, make sure you use a value
/// between those used in [Level.all] and [Level.off].
class Level implements Comparable<Level> {
  final String name;

  /// Unique value for this level. Used to order levels, so filtering can
  /// exclude messages whose level is under certain value.
  final int value;

  const Level(this.name, this.value);

  /// Special key to turn on logging for all levels ([value] = 0).
  static const Level all = Level('all', 0);

  /// Special key to turn off all logging ([value] = 2000).
  static const Level off = Level('off', 2000);

  static const Level verbose = Level('verbose', 300);

  static const Level debug = Level('debug', 500);

  static const Level info = Level('info', 800);

  static const Level warning = Level('warning', 900);

  static const Level error = Level('error', 1000);

  static const List<Level> levels = [
    all,
    verbose,
    debug,
    info,
    warning,
    error,
    off,
  ];

  @override
  bool operator ==(Object other) => other is Level && value == other.value;

  bool operator <(Level other) => value < other.value;

  bool operator <=(Level other) => value <= other.value;

  bool operator >(Level other) => value > other.value;

  bool operator >=(Level other) => value >= other.value;

  @override
  int compareTo(Level other) => value - other.value;

  @override
  int get hashCode => value;

  @override
  String toString() => name;
}
