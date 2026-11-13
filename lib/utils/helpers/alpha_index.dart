/// Logic for A–Z index bars: which letter a name belongs under, how names are
/// ordered, and where to jump for a tapped letter. Pure Dart so it is unit
/// tested; the Artists, Genres and Tracks screens all share it.
///
/// Rules (same everywhere, so an index bar always agrees with its list):
///  * Accents are ignored: "Émile" is under E, "Ångström" under A.
///  * Leading punctuation is ignored: "(Intro)" is under I, "'Til Tuesday"
///    under T.
///  * Anything that is not A–Z after that (digits, other alphabets, empty
///    names) is grouped under '#'.
class AlphaIndex {
  AlphaIndex._();

  /// '#' first, then A–Z: the order the groups appear in a sorted list.
  static const List<String> letters = [
    '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const String other = '#';

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
    'ß': 's',
  };

  static final RegExp _alphanumeric = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Lower-case, accent-folded, with leading punctuation/spaces removed.
  /// Used both to pick the bucket and to sort.
  static String sortKey(String? name) {
    if (name == null) return '';
    final lower = name.toLowerCase();
    final start = lower.indexOf(_alphanumeric);
    if (start == -1) return '';
    final buf = StringBuffer();
    for (final rune in lower.substring(start).runes) {
      final ch = String.fromCharCode(rune);
      buf.write(_accents[ch] ?? ch);
    }
    return buf.toString();
  }

  /// 'A'..'Z' or '#'.
  static String bucketFor(String? name) {
    // Android's placeholder for a missing artist/genre isn't a real name.
    if (name != null && name.trim().toLowerCase() == '<unknown>') return other;
    final key = sortKey(name);
    if (key.isEmpty) return other;
    final first = key[0].toUpperCase();
    final code = first.codeUnitAt(0);
    return (code >= 65 && code <= 90) ? first : other;
  }

  /// Orders names by group ('#' first) and then alphabetically, ignoring
  /// case, accents and leading punctuation.
  static int compareNames(String? a, String? b) {
    final bucketA = letters.indexOf(bucketFor(a));
    final bucketB = letters.indexOf(bucketFor(b));
    if (bucketA != bucketB) return bucketA.compareTo(bucketB);
    final keyed = sortKey(a).compareTo(sortKey(b));
    if (keyed != 0) return keyed;
    return (a ?? '').compareTo(b ?? '');
  }

  /// For a list already in display order: the index where each group first
  /// appears. Groups that don't occur are absent.
  static Map<String, int> firstIndexByBucket(Iterable<String?> names) {
    final result = <String, int>{};
    var i = 0;
    for (final name in names) {
      result.putIfAbsent(bucketFor(name), () => i);
      i++;
    }
    return result;
  }

  /// The letter to jump to for a tapped [letter]: itself if present, else the
  /// next present one after it, else the nearest one before it. Null when no
  /// group is present at all.
  static String? resolve(String letter, Iterable<String> present) {
    final have = present.toSet();
    if (have.isEmpty) return null;
    final start = letters.indexOf(letter);
    if (start == -1) return null;
    for (var i = start; i < letters.length; i++) {
      if (have.contains(letters[i])) return letters[i];
    }
    for (var i = start - 1; i >= 0; i--) {
      if (have.contains(letters[i])) return letters[i];
    }
    return null;
  }

  /// Maps a position along an index bar (0.0 top .. 1.0 bottom) to a letter.
  static String letterAtFraction(double fraction) {
    final index = (fraction * letters.length).floor();
    return letters[index.clamp(0, letters.length - 1)];
  }
}
