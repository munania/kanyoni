/// The bits of a song needed to recognise it. Pure data so the matching
/// rules below can be unit tested without the audio plugin.
class SongIdentity {
  final int id;
  final String path;
  final String title;
  final String artist;
  final int? duration;

  const SongIdentity({
    required this.id,
    required this.path,
    required this.title,
    this.artist = '',
    this.duration,
  });

  String get metaKey =>
      '${title.trim().toLowerCase()}|${artist.trim().toLowerCase()}|$duration';
}

/// An index over the song library, built once and reused for every playlist.
class LibraryIndex {
  final List<SongIdentity> songs;
  final Map<String, int> _byPath = {};
  final Map<String, List<int>> _byMeta = {};

  LibraryIndex(this.songs) {
    for (var i = 0; i < songs.length; i++) {
      final s = songs[i];
      if (s.path.isNotEmpty) _byPath[s.path] = i;
      (_byMeta[s.metaKey] ??= []).add(i);
    }
  }

  /// For every playlist entry, the index of the library song it refers to,
  /// or null when the library has no such song (deleted, or hidden by the
  /// blacklist / minimum length filter).
  ///
  /// The file path identifies a song exactly. Only when the path is unknown
  /// is title+artist+duration used, and then every entry prefers a library
  /// song that no other entry has claimed yet, so two different files that
  /// share their tags aren't collapsed into one.
  List<int?> matchEntries(List<SongIdentity> entries) {
    final claimed = <int>{};
    final result = <int?>[];
    for (final entry in entries) {
      final byPath = entry.path.isEmpty ? null : _byPath[entry.path];
      if (byPath != null) {
        claimed.add(byPath);
        result.add(byPath);
        continue;
      }
      final candidates = _byMeta[entry.metaKey];
      if (candidates == null || candidates.isEmpty) {
        result.add(null);
        continue;
      }
      final pick = candidates.firstWhere(
        (i) => !claimed.contains(i),
        orElse: () => candidates.first,
      );
      claimed.add(pick);
      result.add(pick);
    }
    return result;
  }
}

class PlaylistNames {
  PlaylistNames._();

  static const int maxLength = 60;
  static const String appTag = '[kanyoni]';

  /// Trims, collapses spaces and removes the internal "[kanyoni]" tag.
  static String clean(String raw) =>
      raw.replaceAll(appTag, '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Error text for an unacceptable name, or null when it is fine.
  /// [existing] are the other playlists' display names.
  static String? validate(String raw, Iterable<String> existing) {
    final name = clean(raw);
    if (name.isEmpty) return 'Enter a name';
    if (name.length > maxLength) return 'Too long (max $maxLength characters)';
    final lower = name.toLowerCase();
    if (existing.any((e) => clean(e).toLowerCase() == lower)) {
      return 'A playlist with this name already exists';
    }
    return null;
  }
}
