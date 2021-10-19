library dog.util;

import 'package:tuple/tuple.dart';

part 'unicode_table.dart';

int charWidth(int c) {
  assert(c >= 0 && c <= 0x10FFFF);
  if (_charInTable(_ascii_table, c)) {
    return 1;
  } else if (_charInTable(_private_table, c)) {
    return 1;
  } else if (_charInTable(_nonprint_table, c)) {
    return 0;
  } else if (_charInTable(_doublewide_table, c)) {
    return 2;
  } else if (_charInTable(_combining_table, c)) {
    return 1; // or 0?
  } else if (_charInTable(_ambiguous_table, c)) {
    return 1;
  } else if (_charInTable(_widened_table, c)) {
    return 2; // or maybe 1, renderer dependent
  } else if (_charInTable(_unassigned_table, c)) {
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
