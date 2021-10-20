library dog.util;

import 'package:tuple/tuple.dart';

part 'unicode_table.dart';

int charWidth(int c) {
  assert(c >= 0 && c <= 0x10FFFF);
  if (_charInTable(_asciiTable, c)) {
    return 1;
  } else if (_charInTable(_privateTable, c)) {
    return 1;
  } else if (_charInTable(_nonprintTable, c)) {
    return 0;
  } else if (_charInTable(_doublewideTable, c)) {
    return 2;
  } else if (_charInTable(_combiningTable, c)) {
    return 1; // or 0?
  } else if (_charInTable(_ambiguousTable, c)) {
    return 1;
  } else if (_charInTable(_widenedTable, c)) {
    return 2; // or maybe 1, renderer dependent
  } else if (_charInTable(_unassignedTable, c)) {
    return 1;
  }
  return 1;
}

bool _charInTable(List<Tuple2> table, int c) {
  for (Tuple2 tuple in table) {
    if (c >= tuple.item1 && c <= tuple.item2) {
      return true;
    }
  }
  return false;
}
