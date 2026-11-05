import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/features/lyrics/lrc_parser.dart';

void main() {
  group('LrcParser.parse', () {
    test('parses timestamps with 1, 2 and 3 digit fractions', () {
      final r = LrcParser.parse(
        '[00:01.5] one\n[00:02.50] two\n[00:03.500] three\n[01:04.05] four',
      );
      expect(r.synced, isTrue);
      expect(r.lines.length, equals(4));
      expect(r.lines[0].time.inMilliseconds, equals(1500));
      expect(r.lines[1].time.inMilliseconds, equals(2500));
      expect(r.lines[2].time.inMilliseconds, equals(3500));
      expect(r.lines[3].time.inMilliseconds, equals(64050));
    });

    test('a line with several timestamps is expanded and sorted', () {
      final r = LrcParser.parse('[00:30.00]chorus\n[00:10.00][01:00.00]repeat');
      expect(
        r.lines.map((l) => l.text).toList(),
        equals(['repeat', 'chorus', 'repeat']),
      );
      expect(r.lines[2].time.inSeconds, equals(60));
    });

    test('metadata tags are ignored and [offset] shifts lines earlier', () {
      final r = LrcParser.parse(
        '[ar:Someone]\n[ti:Song]\n[offset:+500]\n'
        '[00:10.00]hello\n[00:00.20]early',
      );
      expect(r.lines.length, equals(2));
      expect(r.lines[0].text, equals('early'));
      expect(r.lines[0].time.inMilliseconds, equals(0)); // clamped at 0
      expect(r.lines[1].time.inMilliseconds, equals(9500));
    });

    test('strips enhanced-LRC word timestamps', () {
      final r = LrcParser.parse('[00:05.00]<00:05.00>Hel<00:05.40>lo');
      expect(r.lines.single.text, equals('Hello'));
    });

    test('handles CRLF and blank timestamp lines', () {
      final r = LrcParser.parse('[00:01.00]a\r\n[00:02.00]\r\n[00:03.00]b');
      expect(r.lines.map((l) => l.text).toList(), equals(['a', 'b']));
    });

    test('plain text is returned unsynced with stanza breaks kept', () {
      final r = LrcParser.parse('line one\nline two\n\n\nline three\n');
      expect(r.synced, isFalse);
      expect(
        r.lines.map((l) => l.text).toList(),
        equals(['line one', 'line two', '', 'line three']),
      );
    });

    test('empty input gives empty result', () {
      expect(LrcParser.parse('').lines, isEmpty);
      expect(LrcParser.parse('   \n  ').synced, isFalse);
    });
  });

  group('LrcParser.indexAt', () {
    final lines = LrcParser.parse('[00:05.00]a\n[00:10.00]b\n[00:20.00]c')
        .lines;

    test('before the first line is -1', () {
      expect(LrcParser.indexAt(lines, const Duration(seconds: 2)), equals(-1));
    });

    test('finds the last line that has started', () {
      expect(LrcParser.indexAt(lines, const Duration(seconds: 5)), equals(0));
      expect(LrcParser.indexAt(lines, const Duration(seconds: 15)), equals(1));
      expect(LrcParser.indexAt(lines, const Duration(minutes: 5)), equals(2));
    });

    test('empty list is -1', () {
      expect(
        LrcParser.indexAt(const [], const Duration(seconds: 1)),
        equals(-1),
      );
    });
  });
}
