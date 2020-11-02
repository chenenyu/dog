/// If you define your own level, make sure you use a value
/// between those used in [Level.ALL] and [Level.OFF].
class Level implements Comparable<Level> {
  final String name;

  /// Unique value for this level. Used to order levels, so filtering can
  /// exclude messages whose level is under certain value.
  final int value;

  const Level(this.name, this.value);

  /// Special key to turn on logging for all levels ([value] = 0).
  static const Level ALL = Level('ALL', 0);

  /// Special key to turn off all logging ([value] = 2000).
  static const Level OFF = Level('OFF', 2000);

  static const Level VERBOSE = Level('VERBOSE', 300);

  static const Level DEBUG = Level('DEBUG', 500);

  static const Level INFO = Level('INFO', 800);

  static const Level WARNING = Level('WARNING', 900);

  static const Level ERROR = Level('ERROR', 1000);

  static const List<Level> LEVELS = [
    ALL,
    VERBOSE,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    OFF
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
