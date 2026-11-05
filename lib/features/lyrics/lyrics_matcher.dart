import 'lyrics_model.dart';

/// What we know about the song we want lyrics for.
class LyricsQuery {
  final String title;
  final String artist;
  final String album;

  /// File name without extension; used as a fallback when tags are missing
  /// or junk ("Artist - Title" is a very common file name).
  final String fileName;

  /// Song length in seconds, 0 when unknown.
  final double durationSec;

  const LyricsQuery({
    required this.title,
    this.artist = '',
    this.album = '',
    this.fileName = '',
    this.durationSec = 0,
  });
}

/// Pure-Dart logic that decides *what to search for* and *which result is
/// really this song*. Most "wrong or missing lyrics" problems come from here:
/// dirty tags make exact lookups miss, and taking the first search hit picks
/// covers, remixes or other songs.
class LyricsMatcher {
  LyricsMatcher._();

  /// Results whose length differs from the file by more than this are a
  /// different recording; their timestamps would drift, so we reject them.
  static const double maxDurationDiffSec = 8;

  // ---------------------------------------------------------------------------
  // Normalising tags
  // ---------------------------------------------------------------------------

  static bool isUnknown(String? value) {
    if (value == null) return true;
    final v = value.trim().toLowerCase();
    return v.isEmpty ||
        v == '<unknown>' ||
        v == 'unknown' ||
        v == 'unknown artist' ||
        v == 'various artists';
  }

  static final RegExp _extension = RegExp(
    r'\.(mp3|flac|m4a|wav|ogg|opus|aac|wma|mp4|webm)$',
    caseSensitive: false,
  );

  // "01 - Song", "01. Song", "1) Song"; needs a separator followed by a
  // space so titles like "1-800-273-8255" or "99 Problems" are left alone.
  static final RegExp _leadingTrackNumber = RegExp(r'^\s*\d{1,3}\s*[-–.)]\s+');
  static final RegExp _leadingUnderscoreNumber = RegExp(r'^\d{2}_');

  // Bracketed text that is clearly not part of the song title.
  static final RegExp _noiseBrackets = RegExp(
    r'\s*[\(\[\{][^\)\]\}]*'
    r'(official|video|audio|lyric|visuali[sz]er|remaster|explicit|\bhd\b|\bhq\b|4k|\bmv\b|m/v|feat\b|feat\.|\bft\b|\bft\.|featuring|prod\b|prod\.|bonus|deluxe|clean version)'
    r'[^\)\]\}]*[\)\]\}]',
    caseSensitive: false,
  );

  // Any bracketed text at all (used for the most aggressive variant).
  static final RegExp _anyBrackets = RegExp(r'\s*[\(\[\{][^\)\]\}]*[\)\]\}]');

  static final RegExp _trailingFeat = RegExp(
    r'\s+(feat\.?|ft\.?|featuring)\s+.+$',
    caseSensitive: false,
  );

  static final RegExp _trailingVersion = RegExp(
    r'\s+[-–]\s+(\d{4}\s+)?(remaster(ed)?|mono|stereo|radio edit|single edit|single version|album version|.*\bversion\b|.*\bremaster(ed)?\b).*$',
    caseSensitive: false,
  );

  static final RegExp _pipeSuffix = RegExp(r'\s*\|.*$');

  /// Light clean-up: file extension, track number, obvious noise in
  /// brackets, "feat." suffixes. Keeps "(Live)", "(Acoustic)", "(Remix)"
  /// because those can legitimately be a different version.
  static String cleanTitle(String raw) {
    var t = raw.trim();
    t = t.replaceFirst(_extension, '');
    t = t.replaceFirst(_leadingTrackNumber, '');
    t = t.replaceFirst(_leadingUnderscoreNumber, '');
    if (!t.contains(' ') && t.contains('_')) t = t.replaceAll('_', ' ');
    for (var i = 0; i < 3; i++) {
      final next = t.replaceFirst(_noiseBrackets, '');
      if (next == t) break;
      t = next;
    }
    t = t.replaceFirst(_pipeSuffix, '');
    t = t.replaceFirst(_trailingVersion, '');
    t = t.replaceFirst(_trailingFeat, '');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Everything in brackets removed too: "Song (Live at X)" -> "Song".
  static String stripAllBrackets(String raw) {
    return cleanTitle(raw)
        .replaceAll(_anyBrackets, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Artist without " - Topic" (YouTube auto channels) and feat. credits.
  static String cleanArtist(String raw) {
    if (isUnknown(raw)) return '';
    var a = raw.trim();
    a = a.replaceFirst(RegExp(r'\s*-\s*topic$', caseSensitive: false), '');
    a = a.replaceFirst(_trailingFeat, '');
    return a.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// First credited artist: "A feat. B" / "A, B" / "A; B" / "A x B" -> "A".
  /// '&' and '/' are NOT split here because they appear in real names
  /// ("Simon & Garfunkel", "AC/DC").
  static String primaryArtist(String raw) {
    final a = cleanArtist(raw);
    if (a.isEmpty) return '';
    final first = a.split(RegExp(r'\s*(?:,|;|\sx\s)\s*')).first.trim();
    return first.isEmpty ? a : first;
  }

  /// Guesses (artist, title) from a "Artist - Title" file name.
  static ({String artist, String title})? parseFileName(String fileName) {
    var name = fileName.trim().replaceFirst(_extension, '');
    name = name.replaceFirst(_leadingTrackNumber, '');
    name = name.replaceFirst(_leadingUnderscoreNumber, '');
    final parts = name.split(RegExp(r'\s+[-–]\s+'));
    if (parts.length < 2) return null;
    final artist = parts.first.trim();
    final title = parts.sublist(1).join(' - ').trim();
    if (artist.isEmpty || title.isEmpty) return null;
    return (artist: artist, title: title);
  }

  /// Distinct title strings to try, best first.
  static List<String> titleVariants(LyricsQuery q) {
    final out = <String>[];
    void add(String s) {
      final v = s.trim();
      if (v.isEmpty) return;
      if (!out.any((e) => normalize(e) == normalize(v))) out.add(v);
    }

    final rawTitle = isUnknown(q.title) ? '' : q.title;
    add(cleanTitle(rawTitle));
    add(stripAllBrackets(rawTitle));

    // Title tag is "Artist - Title": drop the artist part.
    final artist = cleanArtist(q.artist);
    final fromTitle = parseFileName(rawTitle);
    if (fromTitle != null &&
        (artist.isEmpty || similarity(fromTitle.artist, artist) >= 0.8)) {
      add(cleanTitle(fromTitle.title));
    }

    // File name fallback / extra variant.
    final fromFile = parseFileName(q.fileName);
    if (fromFile != null) add(cleanTitle(fromFile.title));
    if (out.isEmpty) add(cleanTitle(q.fileName));
    if (out.isEmpty) add(rawTitle);
    return out;
  }

  /// Distinct artist strings to try, best first. May be empty.
  static List<String> artistVariants(LyricsQuery q) {
    final out = <String>[];
    void add(String s) {
      final v = s.trim();
      if (v.isEmpty) return;
      if (!out.any((e) => normalize(e) == normalize(v))) out.add(v);
    }

    add(cleanArtist(q.artist));
    add(primaryArtist(q.artist));

    final rawTitle = isUnknown(q.title) ? '' : q.title;
    final fromTitle = parseFileName(rawTitle);
    if (out.isEmpty && fromTitle != null) add(cleanArtist(fromTitle.artist));
    final fromFile = parseFileName(q.fileName);
    if (out.isEmpty && fromFile != null) add(cleanArtist(fromFile.artist));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Comparing strings
  // ---------------------------------------------------------------------------

  static const Map<String, String> _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ā': 'a',
    'ç': 'c',
    'ć': 'c',
    'č': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ē': 'e',
    'ę': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ī': 'i',
    'ñ': 'n',
    'ń': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'ō': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ū': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'š': 's',
    'ś': 's',
    'ž': 'z',
    'ź': 'z',
    'ż': 'z',
    'ł': 'l',
    'ß': 'ss',
  };

  static final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  /// Lower-case, accent-folded, punctuation-free, single-spaced.
  static String normalize(String s) {
    // Apostrophes are dropped (not turned into spaces) so "Don't" == "Dont".
    final lower = s
        .toLowerCase()
        .replaceAll(RegExp("['\u2019\u2018`\u00B4]"), '')
        .replaceAll('&', ' and ');
    final buf = StringBuffer();
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      buf.write(_accents[ch] ?? ch);
    }
    return buf
        .toString()
        .replaceAll(_nonWord, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 0..1. Exact (after normalising) = 1, one contains the other = 0.85,
  /// otherwise word overlap (Jaccard).
  static double similarity(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1;
    if (na.length >= 3 &&
        nb.length >= 3 &&
        (na.contains(nb) || nb.contains(na))) {
      return 0.85;
    }
    final wa = na.split(' ').toSet();
    final wb = nb.split(' ').toSet();
    final inter = wa.intersection(wb).length;
    final union = wa.union(wb).length;
    return union == 0 ? 0 : inter / union;
  }

  // ---------------------------------------------------------------------------
  // Choosing the right result
  // ---------------------------------------------------------------------------

  /// Score of [c] as a match for [q], or null when it must be rejected.
  static double? score(LyricsModel c, LyricsQuery q) {
    if (!c.hasAnyText && !c.instrumental) return null;

    final titles = titleVariants(q);
    final artists = artistVariants(q);

    var titleSim = 0.0;
    for (final t in titles) {
      final s = similarity(t, c.trackName);
      if (s > titleSim) titleSim = s;
    }
    if (titleSim < 0.6) return null;

    final hasDuration = q.durationSec > 0 && c.duration > 0;
    final diff = hasDuration ? (q.durationSec - c.duration).abs() : null;
    if (diff != null && diff > maxDurationDiffSec) return null;

    var artistSim = 0.0;
    if (artists.isNotEmpty) {
      for (final a in artists) {
        final s = similarity(a, c.artistName);
        if (s > artistSim) artistSim = s;
      }
      // A different artist is only acceptable when everything else says
      // "same recording" (tags are often wrong or list a different credit).
      if (artistSim < 0.4) {
        final strongTitle = titleSim >= 0.9;
        final strongDuration = diff != null && diff <= 2;
        if (!(strongTitle && strongDuration)) return null;
      }
    }

    final durationScore = diff == null ? 0.5 : 1 - (diff / maxDurationDiffSec);
    final syncedBonus = c.hasSynced ? 0.25 : 0.0;
    return titleSim + artistSim * 0.6 + durationScore * 1.2 + syncedBonus;
  }

  /// The best acceptable candidate, or null if none really matches.
  static LyricsModel? pickBest(
    Iterable<LyricsModel> candidates,
    LyricsQuery q,
  ) {
    LyricsModel? best;
    var bestScore = -1.0;
    for (final c in candidates) {
      final s = score(c, q);
      if (s != null && s > bestScore) {
        best = c;
        bestScore = s;
      }
    }
    return best;
  }
}
