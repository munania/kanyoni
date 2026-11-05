import 'lyrics_model.dart';

/// The result of parsing lyrics text.
class ParsedLyrics {
  /// Lines in display order. For synced lyrics they are sorted by time; for
  /// plain lyrics every line has [Duration.zero] and blank lines are kept as
  /// empty-text lines so stanza breaks survive.
  final List<LyricLine> lines;

  /// True when the lines carry real timestamps and can be highlighted in
  /// time with the song.
  final bool synced;

  const ParsedLyrics(this.lines, {required this.synced});

  static const ParsedLyrics empty = ParsedLyrics([], synced: false);
}

/// Parser for LRC ("[mm:ss.xx] text") lyrics. Pure Dart so it is unit-tested.
class LrcParser {
  LrcParser._();

  // [mm:ss], [mm:ss.x], [mm:ss.xx], [mm:ss.xxx] (also accepts ':' before the
  // fraction, which some tools emit).
  static final RegExp _timeTag = RegExp(
    r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]',
  );

  // Metadata tags such as [ar:Artist], [ti:Title], [offset:+250].
  static final RegExp _metaTag = RegExp(r'^\[([A-Za-z#]+):(.*)\]\s*$');

  // "Enhanced LRC" word timestamps inside a line: <00:12.34>
  static final RegExp _wordTag = RegExp(r'<\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?>');

  static Duration _toDuration(Match m) {
    final minutes = int.parse(m.group(1)!);
    final seconds = int.parse(m.group(2)!);
    final fraction = m.group(3);
    var millis = 0;
    if (fraction != null) {
      // "5" -> 500ms, "50" -> 500ms, "500" -> 500ms
      millis = int.parse(fraction.padRight(3, '0'));
    }
    return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
  }

  /// Parses [raw]. Returns synced lines when any timestamped line exists,
  /// otherwise the text as plain (unsynced) lines.
  static ParsedLyrics parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final synced = <_Timed>[];
    final plain = <String>[];
    var offsetMs = 0;
    var order = 0;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        if (plain.isNotEmpty && plain.last.isNotEmpty) plain.add('');
        continue;
      }

      final meta = _metaTag.firstMatch(line);
      if (meta != null) {
        if (meta.group(1)!.toLowerCase() == 'offset') {
          offsetMs =
              int.tryParse(meta.group(2)!.trim().replaceFirst('+', '')) ?? 0;
        }
        continue;
      }

      // A line may start with several timestamps: "[00:10.00][00:50.00]text"
      final times = <Duration>[];
      var index = 0;
      while (true) {
        final m = _timeTag.matchAsPrefix(line, index);
        if (m == null) break;
        times.add(_toDuration(m));
        index = m.end;
      }

      if (times.isEmpty) {
        plain.add(line);
        continue;
      }

      final content = line.substring(index).replaceAll(_wordTag, '').trim();
      if (content.isEmpty) continue;

      for (final t in times) {
        synced.add(_Timed(t, content, order++));
      }
    }

    if (synced.isNotEmpty) {
      // LRC [offset:+n] means the lyrics should appear n ms *earlier*.
      final shifted =
          synced.map((e) {
            final ms = e.time.inMilliseconds - offsetMs;
            return _Timed(
              Duration(milliseconds: ms < 0 ? 0 : ms),
              e.text,
              e.order,
            );
          }).toList()..sort((a, b) {
            final c = a.time.compareTo(b.time);
            return c != 0 ? c : a.order.compareTo(b.order);
          });
      return ParsedLyrics(
        shifted.map((e) => LyricLine(time: e.time, text: e.text)).toList(),
        synced: true,
      );
    }

    while (plain.isNotEmpty && plain.last.isEmpty) {
      plain.removeLast();
    }
    if (plain.isEmpty) return ParsedLyrics.empty;
    return ParsedLyrics(
      plain.map((t) => LyricLine(time: Duration.zero, text: t)).toList(),
      synced: false,
    );
  }

  /// Index of the last line whose time is <= [position], or -1 when the song
  /// hasn't reached the first line yet. Binary search: it runs on every
  /// position tick, and lyrics can have hundreds of lines.
  static int indexAt(List<LyricLine> lines, Duration position) {
    var lo = 0;
    var hi = lines.length - 1;
    var result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= position) {
        result = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }
}

class _Timed {
  final Duration time;
  final String text;
  final int order;
  const _Timed(this.time, this.text, this.order);
}
