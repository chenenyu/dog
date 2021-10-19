import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tuple/tuple.dart';

/*
  Refer:
  http://www.unicode.org/reports/tr44/#General_Category_Values
  https://www.compart.com/en/unicode/
 */

const String UNICODE_DATA_URL =
    'http://ftp.unicode.org/Public/UNIDATA/UnicodeData.txt';
const String EAST_ASIAN_WIDTH_URL =
    'http://ftp.unicode.org/Public/UNIDATA/EastAsianWidth.txt';
const String EMOJI_DATA_URL =
    'https://unicode.org/Public/14.0.0/ucd/emoji/emoji-data.txt';

// Maximum codepoint value.
const int MAX_CODEPOINT = 0x110000;

const int FIELD_CODEPOINT = 0;
const int FIELD_NAME = 1;
const int FIELD_CATEGORY = 2;

// Category for unassigned codepoints.
const String CAT_UNASSIGNED = "Cn";
// Category for private use codepoints.
const String CAT_PRIVATE_USE = "Co";
// Category for surrogates.
const String CAT_SURROGATE = "Cs";

// Ambiguous East Asian characters
const int WIDTH_AMBIGUOUS_EASTASIAN = -3;
// Width changed from 1 to 2 in Unicode 9.0
const int WIDTH_WIDENED_IN_9 = -6;

class CodePoint {
  final int codepoint;
  String category = CAT_UNASSIGNED;
  int? width;

  CodePoint(this.codepoint);

  String get hex => '0x${codepoint.toRadixString(16).toUpperCase()}';

  @override
  String toString() {
    return 'CodePoint{codepoint: $hex, category: $category, width: $width}';
  }
}

void main(List<String> args) async {
  List result = await Future.wait([
    _read_datafile(UNICODE_DATA_URL),
    _read_datafile(EAST_ASIAN_WIDTH_URL),
    _read_datafile(EMOJI_DATA_URL),
  ]);
  List<String> unicode_data = result[0];
  List<String> east_asian_width = result[1];
  List<String> emoji_data = result[2];

  print('${DateTime.now().toString()}: Parsing...');
  final List<CodePoint> cps =
      List.generate(MAX_CODEPOINT, (index) => CodePoint(index));
  _set_general_categories(unicode_data, cps);
  _set_east_asian_width(east_asian_width, cps);
  _set_emoji_data(emoji_data, cps);
  _set_hardcoded_ranges(cps);

  _gen(cps);
}

/// Read data from file. Download first if file not exists.
Future<List<String>> _read_datafile(String url) async {
  String name = url.substring(url.lastIndexOf('/') + 1);
  File file = File(p.join(p.dirname(Platform.script.path), name));
  if (!file.existsSync()) {
    print('${DateTime.now().toString()}: Loading $url');
    String contents = await http.read(Uri.parse(url));
    await file.writeAsString(contents, flush: true);
    print('${DateTime.now().toString()}: Write to ${file.path}');
  }
  List<String> lines = file.readAsLinesSync()
    ..removeWhere((line) => line.startsWith('#') || line.trim().isEmpty);
  return lines;
}

/// Read from UnicodeData.txt, and set general categories for codepoints.
void _set_general_categories(
    List<String> unicode_data_lines, List<CodePoint> cps) {
  for (String line in unicode_data_lines) {
    var fields = line.split(';');
    if (fields.length > FIELD_CATEGORY) {
      List<int> range = _hexrange_to_range(fields[FIELD_CODEPOINT]);
      for (int cp in range) {
        cps[cp].category = fields[FIELD_CATEGORY];
      }
    }
  }
}

/// Read from EastAsianWidth.txt, and set width values for the codepoints.
///
/// A: Ambiguous
/// F: Fullwidth 2
/// H: Halfwidth
/// W: Wide 2
/// Na: Narrow
/// N: Neutral
void _set_east_asian_width(
    List<String> east_asian_width_lines, List<CodePoint> cps) {
  void parse_line(String line) {
    line = line.split('#').first;
    List<String> fields = line.trim().split(';');
    if (fields.length != 2) {
      return;
    }
    int width = 1;
    String width_type = fields.last;
    if (width_type == 'A') {
      width = WIDTH_AMBIGUOUS_EASTASIAN; // ambiguous
    } else if (width_type == 'F' || width_type == 'W') {
      width = 2;
    } else {
      width = 1;
    }
    List<int> ranges = _hexrange_to_range(fields.first);
    for (int cp in ranges) {
      cps[cp].width = width;
    }
  }

  for (String line in east_asian_width_lines) {
    parse_line(line);
  }

  /*
  #  - All code points, assigned or unassigned, that are not listed
  #      explicitly are given the value "N".
  #  - The unassigned code points in the following blocks default to "W":
  #         CJK Unified Ideographs Extension A: U+3400..U+4DBF
  #         CJK Unified Ideographs:             U+4E00..U+9FFF
  #         CJK Compatibility Ideographs:       U+F900..U+FAFF
  #  - All undesignated code points in Planes 2 and 3, whether inside or
  #      outside of allocated blocks, default to "W":
  #         Plane 2:                            U+20000..U+2FFFD
  #         Plane 3:                            U+30000..U+3FFFD
   */
  void handle_wide_ranges(List<int> wide_ranges) {
    for (int cp in wide_ranges) {
      cps[cp].width ??= 2;
    }
  }

  handle_wide_ranges(_hexrange_to_range('3400..4DBF'));
  handle_wide_ranges(_hexrange_to_range('4E00..9FFF'));
  handle_wide_ranges(_hexrange_to_range('F900..FAFF'));
  handle_wide_ranges(_hexrange_to_range('20000..2FFFD'));
  handle_wide_ranges(_hexrange_to_range('30000..3FFFD'));
}

/// Read from emoji-data.txt, set codepoint widths
void _set_emoji_data(List<String> emoji_data_lines, List<CodePoint> cps) {
  RegExp reg = RegExp(r'E(\d+\.\d+)\s*');
  Iterable<Tuple2> parse_emoji_line(String line) {
    List<String> fields_comments = line.split('#');
    assert(fields_comments.length >= 2);
    String fields = fields_comments[0];
    String comments = fields_comments[1].trim();
    List<String> cp_prop = fields.split(';');
    assert(cp_prop.length == 2, '${cp_prop}.length != 2');
    String cp_range = cp_prop.first.trim();
    double version = 0;
    RegExpMatch? match = reg.firstMatch(comments);
    assert(match != null);
    version = double.parse(match![1]!);
    List<int> range = _hexrange_to_range(cp_range);
    return range.map((e) => Tuple2<int, double>(e, version));
  }

  for (String line in emoji_data_lines) {
    Iterable<Tuple2> tuples = parse_emoji_line(line);
    for (Tuple2 tuple in tuples) {
      // Don't consider <=1F000 values as emoji.
      if (tuple.item1 < 0x1F000) continue;
      // Skip codepoints that have a version of 0.0 as they were marked
      // in the emoji-data file as reserved/unused:
      if (tuple.item2 <= 1.0) continue;
      // Skip codepoints that are explicitly not wide.
      // For example U+1F336 ("Hot Pepper") renders like any emoji but is
      // marked as neutral in EAW so has width 1 for some reason.
      if (cps[tuple.item1].width == 1) continue;
      // If this emoji was introduced before Unicode 9, then it was widened in 9.
      if (tuple.item2 >= 9.0) {
        cps[tuple.item1].width = 2;
      } else {
        cps[tuple.item1].width =
            WIDTH_WIDENED_IN_9; // maybe 1, renderer dependent
      }
    }
  }
}

/// Can be determined awkwardly from UnicodeData.txt
void _set_hardcoded_ranges(List<CodePoint> cps) {
  // E000;<Private Use, First>;Co;0;L;;;;;N;;;;;
  // F8FF;<Private Use, Last>;Co;0;L;;;;;N;;;;;
  // F0000;<Plane 15 Private Use, First>;Co;0;L;;;;;N;;;;;
  // FFFFD;<Plane 15 Private Use, Last>;Co;0;L;;;;;N;;;;;
  // 100000;<Plane 16 Private Use, First>;Co;0;L;;;;;N;;;;;
  // 10FFFD;<Plane 16 Private Use, Last>;Co;0;L;;;;;N;;;;;
  List<Tuple2<int, int>> private_ranges = [
    Tuple2(0xE000, 0xF8FF),
    Tuple2(0xF0000, 0xFFFFD),
    Tuple2(0x100000, 0x10FFFD),
  ];
  for (Tuple2<int, int> tuple in private_ranges) {
    List<int> range = _tuple_to_range(tuple);
    for (int cp in range) {
      cps[cp].category = CAT_PRIVATE_USE;
    }
  }

  // D800;<Non Private Use High Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DB7F;<Non Private Use High Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  // DB80;<Private Use High Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DBFF;<Private Use High Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  // DC00;<Low Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DFFF;<Low Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  List<Tuple2<int, int>> surrogate_ranges = [
    Tuple2(0xD800, 0xDBFF),
    Tuple2(0xDC00, 0xDFFF),
  ];
  for (Tuple2<int, int> tuple in surrogate_ranges) {
    List<int> range = _tuple_to_range(tuple);
    for (int cp in range) {
      cps[cp].category = CAT_SURROGATE;
    }
  }
}

/// Given a string like 1F300..1F320 representing an inclusive range,
/// return the range of codepoints.
/// If the string is like 1F321, return a range of just that element.
List<int> _hexrange_to_range(String hexrange) {
  List<int> ranges =
      hexrange.split('..').map((e) => int.parse(e, radix: 16)).toList();
  assert(ranges.length <= 2);
  if (ranges.length == 1) {
    return ranges;
  } else {
    return [for (int i = ranges.first; i <= ranges.last; i++) i];
  }
}

List<int> _tuple_to_range(Tuple2<int, int> tuple) {
  return [for (int i = tuple.item1; i <= tuple.item2; i++) i];
}

List<Tuple2<CodePoint, CodePoint>> _merge_codepoints_to_tuples(
    List<CodePoint> cps) {
  if (cps.isEmpty) return [];
  cps.sort((a, b) => a.codepoint.compareTo(b.codepoint));
  List<Tuple2<CodePoint, CodePoint>> tuples = [Tuple2(cps[0], cps[0])];
  for (CodePoint cp in cps.sublist(1)) {
    Tuple2<CodePoint, CodePoint> last_tuple = tuples.last;
    if (cp.codepoint == last_tuple.item2.codepoint + 1) {
      tuples[tuples.length - 1] = last_tuple.withItem2(cp);
      continue;
    }
    tuples.add(Tuple2<CodePoint, CodePoint>(cp, cp));
  }
  return tuples;
}

String _codepoints_to_tuple_str(List<CodePoint> cps) {
  List<Tuple2<CodePoint, CodePoint>> tuples = _merge_codepoints_to_tuples(cps);
  return tuples
      .map((e) => 'Tuple2(${e.item1.hex}, ${e.item2.hex}),')
      .join('\n  ');
}

void _gen(List<CodePoint> cps) {
  print('${DateTime.now().toString()}: Generating...');

  String ascii_codepoints() {
    return _codepoints_to_tuple_str([
      for (CodePoint cp in cps)
        if (cp.codepoint >= 0x20 && cp.codepoint < 0x7F) cp
    ]);
  }

  String categories(List<String> cats) {
    List<CodePoint> matches = [
      for (CodePoint cp in cps)
        if (cats.contains(cp.category)) cp
    ];
    return _codepoints_to_tuple_str(matches);
  }

  String codepoints_with_width(int width) {
    List<CodePoint> matches = [
      for (CodePoint cp in cps)
        if (cp.width == width) cp
    ];
    return _codepoints_to_tuple_str(matches);
  }

  String template = '''
// Generated on ${DateTime.now().toUtc().toString()}
part of dog.util;

List<Tuple2> _ascii_table = [
  ${ascii_codepoints()}
];

List<Tuple2> _private_table = [
  ${categories([CAT_PRIVATE_USE])}
];

List<Tuple2> _nonprint_table = [
  ${categories(['Cc', 'Cf', 'Zl', 'Zp', CAT_SURROGATE])}
];

List<Tuple2> _combining_table = [
  ${categories(["Mn", "Mc", "Me"])}
];

List<Tuple2> _doublewide_table = [
  ${codepoints_with_width(2)}
];

List<Tuple2> _unassigned_table = [
  ${categories([CAT_UNASSIGNED])}
];

List<Tuple2> _ambiguous_table = [
  ${codepoints_with_width(WIDTH_AMBIGUOUS_EASTASIAN)}
];

List<Tuple2> _widened_table = [
  ${codepoints_with_width(WIDTH_WIDENED_IN_9)}
];
''';

  File table_file = File(p.normalize(p.join(p.dirname(Platform.script.path),
      '../', 'lib/src/util/unicode_table.dart')));
  table_file.writeAsStringSync(template);

  print('${DateTime.now().toString()}: Generated to ${table_file.path}');
}
