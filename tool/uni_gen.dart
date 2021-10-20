import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tuple/tuple.dart';

/*
  Refer:
  http://www.unicode.org/reports/tr44/#General_Category_Values
  https://www.compart.com/en/unicode/
 */

const String unicodeDataUrl =
    'http://ftp.unicode.org/Public/UNIDATA/UnicodeData.txt';
const String eastAsianWidthUrl =
    'http://ftp.unicode.org/Public/UNIDATA/EastAsianWidth.txt';
const String emojiDataUrl =
    'https://unicode.org/Public/14.0.0/ucd/emoji/emoji-data.txt';

// Maximum codepoint value.
const int maxCodepoint = 0x110000;

const int fieldCodepoint = 0;
const int fieldName = 1;
const int fieldCategory = 2;

// Category for unassigned codepoints.
const String catUnassigned = "Cn";
// Category for private use codepoints.
const String catPrivateUse = "Co";
// Category for surrogates.
const String catSurrogate = "Cs";

// Ambiguous East Asian characters
const int widthAmbiguousEastasian = -3;
// Width changed from 1 to 2 in Unicode 9.0
const int widthWidenedIn9 = -6;

class CodePoint {
  final int codepoint;
  String category = catUnassigned;
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
    _readDatafile(unicodeDataUrl),
    _readDatafile(eastAsianWidthUrl),
    _readDatafile(emojiDataUrl),
  ]);
  List<String> unicodeData = result[0];
  List<String> eastAsianWidth = result[1];
  List<String> emojiData = result[2];

  print('${DateTime.now().toString()}: Parsing...');
  final List<CodePoint> cps =
      List.generate(maxCodepoint, (index) => CodePoint(index));
  _setGeneralCategories(unicodeData, cps);
  _setEastAsianWidth(eastAsianWidth, cps);
  _setEmojiData(emojiData, cps);
  _setHardcodedRanges(cps);

  _gen(cps);
}

/// Read data from file. Download first if file not exists.
Future<List<String>> _readDatafile(String url) async {
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
void _setGeneralCategories(List<String> unicodeDataLines, List<CodePoint> cps) {
  for (String line in unicodeDataLines) {
    var fields = line.split(';');
    if (fields.length > fieldCategory) {
      List<int> range = _hexrangeToRange(fields[fieldCodepoint]);
      for (int cp in range) {
        cps[cp].category = fields[fieldCategory];
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
void _setEastAsianWidth(List<String> eastAsianWidthLines, List<CodePoint> cps) {
  void parseLine(String line) {
    line = line.split('#').first;
    List<String> fields = line.trim().split(';');
    if (fields.length != 2) {
      return;
    }
    int width = 1;
    String widthType = fields.last;
    if (widthType == 'A') {
      width = widthAmbiguousEastasian; // ambiguous
    } else if (widthType == 'F' || widthType == 'W') {
      width = 2;
    } else {
      width = 1;
    }
    List<int> ranges = _hexrangeToRange(fields.first);
    for (int cp in ranges) {
      cps[cp].width = width;
    }
  }

  for (String line in eastAsianWidthLines) {
    parseLine(line);
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
  void handleWideRanges(List<int> wideRanges) {
    for (int cp in wideRanges) {
      cps[cp].width ??= 2;
    }
  }

  handleWideRanges(_hexrangeToRange('3400..4DBF'));
  handleWideRanges(_hexrangeToRange('4E00..9FFF'));
  handleWideRanges(_hexrangeToRange('F900..FAFF'));
  handleWideRanges(_hexrangeToRange('20000..2FFFD'));
  handleWideRanges(_hexrangeToRange('30000..3FFFD'));
}

/// Read from emoji-data.txt, set codepoint widths
void _setEmojiData(List<String> emojiDataLines, List<CodePoint> cps) {
  RegExp reg = RegExp(r'E(\d+\.\d+)\s*');
  Iterable<Tuple2> parseEmojiLine(String line) {
    List<String> fieldsComments = line.split('#');
    assert(fieldsComments.length >= 2);
    String fields = fieldsComments[0];
    String comments = fieldsComments[1].trim();
    List<String> cpProp = fields.split(';');
    assert(cpProp.length == 2, '$cpProp.length != 2');
    String cpRange = cpProp.first.trim();
    double version = 0;
    RegExpMatch? match = reg.firstMatch(comments);
    assert(match != null);
    version = double.parse(match![1]!);
    List<int> range = _hexrangeToRange(cpRange);
    return range.map((e) => Tuple2<int, double>(e, version));
  }

  for (String line in emojiDataLines) {
    Iterable<Tuple2> tuples = parseEmojiLine(line);
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
        cps[tuple.item1].width = widthWidenedIn9; // maybe 1, renderer dependent
      }
    }
  }
}

/// Can be determined awkwardly from UnicodeData.txt
void _setHardcodedRanges(List<CodePoint> cps) {
  // E000;<Private Use, First>;Co;0;L;;;;;N;;;;;
  // F8FF;<Private Use, Last>;Co;0;L;;;;;N;;;;;
  // F0000;<Plane 15 Private Use, First>;Co;0;L;;;;;N;;;;;
  // FFFFD;<Plane 15 Private Use, Last>;Co;0;L;;;;;N;;;;;
  // 100000;<Plane 16 Private Use, First>;Co;0;L;;;;;N;;;;;
  // 10FFFD;<Plane 16 Private Use, Last>;Co;0;L;;;;;N;;;;;
  List<Tuple2<int, int>> privateRanges = [
    Tuple2(0xE000, 0xF8FF),
    Tuple2(0xF0000, 0xFFFFD),
    Tuple2(0x100000, 0x10FFFD),
  ];
  for (Tuple2<int, int> tuple in privateRanges) {
    List<int> range = _tupleToRange(tuple);
    for (int cp in range) {
      cps[cp].category = catPrivateUse;
    }
  }

  // D800;<Non Private Use High Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DB7F;<Non Private Use High Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  // DB80;<Private Use High Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DBFF;<Private Use High Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  // DC00;<Low Surrogate, First>;Cs;0;L;;;;;N;;;;;
  // DFFF;<Low Surrogate, Last>;Cs;0;L;;;;;N;;;;;
  List<Tuple2<int, int>> surrogateRanges = [
    Tuple2(0xD800, 0xDBFF),
    Tuple2(0xDC00, 0xDFFF),
  ];
  for (Tuple2<int, int> tuple in surrogateRanges) {
    List<int> range = _tupleToRange(tuple);
    for (int cp in range) {
      cps[cp].category = catSurrogate;
    }
  }
}

/// Given a string like 1F300..1F320 representing an inclusive range,
/// return the range of codepoints.
/// If the string is like 1F321, return a range of just that element.
List<int> _hexrangeToRange(String hexrange) {
  List<int> ranges =
      hexrange.split('..').map((e) => int.parse(e, radix: 16)).toList();
  assert(ranges.length <= 2);
  if (ranges.length == 1) {
    return ranges;
  } else {
    return [for (int i = ranges.first; i <= ranges.last; i++) i];
  }
}

List<int> _tupleToRange(Tuple2<int, int> tuple) {
  return [for (int i = tuple.item1; i <= tuple.item2; i++) i];
}

List<Tuple2<CodePoint, CodePoint>> _mergeCodepointsToTuples(
    List<CodePoint> cps) {
  if (cps.isEmpty) return [];
  cps.sort((a, b) => a.codepoint.compareTo(b.codepoint));
  List<Tuple2<CodePoint, CodePoint>> tuples = [Tuple2(cps[0], cps[0])];
  for (CodePoint cp in cps.sublist(1)) {
    Tuple2<CodePoint, CodePoint> lastTuple = tuples.last;
    if (cp.codepoint == lastTuple.item2.codepoint + 1) {
      tuples[tuples.length - 1] = lastTuple.withItem2(cp);
      continue;
    }
    tuples.add(Tuple2<CodePoint, CodePoint>(cp, cp));
  }
  return tuples;
}

String _codepointsToTupleStr(List<CodePoint> cps) {
  List<Tuple2<CodePoint, CodePoint>> tuples = _mergeCodepointsToTuples(cps);
  return tuples
      .map((e) => 'Tuple2(${e.item1.hex}, ${e.item2.hex}),')
      .join('\n  ');
}

void _gen(List<CodePoint> cps) {
  print('${DateTime.now().toString()}: Generating...');

  String asciiCodepoints() {
    return _codepointsToTupleStr([
      for (CodePoint cp in cps)
        if (cp.codepoint >= 0x20 && cp.codepoint < 0x7F) cp
    ]);
  }

  String categories(List<String> cats) {
    List<CodePoint> matches = [
      for (CodePoint cp in cps)
        if (cats.contains(cp.category)) cp
    ];
    return _codepointsToTupleStr(matches);
  }

  String codepointsWithWidth(int width) {
    List<CodePoint> matches = [
      for (CodePoint cp in cps)
        if (cp.width == width) cp
    ];
    return _codepointsToTupleStr(matches);
  }

  String template = '''
// Generated on ${DateTime.now().toUtc().toString()}
part of dog.util;

List<Tuple2> _asciiTable = [
  ${asciiCodepoints()}
];

List<Tuple2> _privateTable = [
  ${categories([catPrivateUse])}
];

List<Tuple2> _nonprintTable = [
  ${categories(['Cc', 'Cf', 'Zl', 'Zp', catSurrogate])}
];

List<Tuple2> _combiningTable = [
  ${categories(["Mn", "Mc", "Me"])}
];

List<Tuple2> _doublewideTable = [
  ${codepointsWithWidth(2)}
];

List<Tuple2> _unassignedTable = [
  ${categories([catUnassigned])}
];

List<Tuple2> _ambiguousTable = [
  ${codepointsWithWidth(widthAmbiguousEastasian)}
];

List<Tuple2> _widenedTable = [
  ${codepointsWithWidth(widthWidenedIn9)}
];
''';

  File tableFile = File(p.normalize(p.join(p.dirname(Platform.script.path),
      '../', 'lib/src/util/unicode_table.dart')));
  tableFile.writeAsStringSync(template);

  print('${DateTime.now().toString()}: Generated to ${tableFile.path}');
}
