/// File types the tag writer can handle. Anything else (wav, aac, wma...) is
/// shown as "not editable" instead of failing half way.
const Set<String> kEditableExtensions = {
  'mp3',
  'flac',
  'm4a',
  'mp4',
  'ogg',
  'oga',
  'opus',
};

bool isEditableExtension(String? extension) {
  if (extension == null) return false;
  final e = extension.trim().toLowerCase().replaceFirst('.', '');
  return kEditableExtensions.contains(e);
}

/// The text tags the editor works with. Pure Dart so the rules (what counts
/// as a change, what is valid) are unit tested.
class SongTags {
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final String year;
  final String track;

  const SongTags({
    this.title = '',
    this.artist = '',
    this.album = '',
    this.albumArtist = '',
    this.genre = '',
    this.year = '',
    this.track = '',
  });

  /// Keys shared with the native side.
  static const List<String> fields = [
    'title',
    'artist',
    'album',
    'albumArtist',
    'genre',
    'year',
    'track',
  ];

  static const int maxTextLength = 255;

  factory SongTags.fromMap(Map<dynamic, dynamic>? map) {
    String read(String key) {
      final v = map?[key];
      return v is String ? v.trim() : '';
    }

    return SongTags(
      title: read('title'),
      artist: read('artist'),
      album: read('album'),
      albumArtist: read('albumArtist'),
      genre: read('genre'),
      year: _cleanYear(read('year')),
      track: read('track'),
    );
  }

  Map<String, String> toMap() => {
    'title': title,
    'artist': artist,
    'album': album,
    'albumArtist': albumArtist,
    'genre': genre,
    'year': year,
    'track': track,
  };

  String valueOf(String field) => toMap()[field] ?? '';

  SongTags copyWith({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    String? year,
    String? track,
  }) {
    return SongTags(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      track: track ?? this.track,
    );
  }

  /// Everything trimmed, so stray spaces never count as an edit.
  ///
  /// Deliberately trim-only: user input must never be silently "repaired"
  /// (that would turn an invalid year into an empty one and erase the tag).
  /// Cleaning of values read from files happens in [SongTags.fromMap].
  SongTags normalized() => SongTags(
    title: title.trim(),
    artist: artist.trim(),
    album: album.trim(),
    albumArtist: albumArtist.trim(),
    genre: genre.trim(),
    year: year.trim(),
    track: track.trim(),
  );

  /// Only the fields whose value differs from [original] (both normalised).
  /// An empty string means "clear this tag".
  Map<String, String> changesFrom(SongTags original) {
    final mine = normalized().toMap();
    final theirs = original.normalized().toMap();
    return {
      for (final f in fields)
        if (mine[f] != theirs[f]) f: mine[f]!,
    };
  }

  /// Field name -> error message. Empty when everything is valid.
  Map<String, String> validate() {
    final t = normalized();
    final errors = <String, String>{};

    if (t.title.isEmpty) errors['title'] = 'Title can\'t be empty';

    for (final f in const [
      'title',
      'artist',
      'album',
      'albumArtist',
      'genre',
    ]) {
      if (t.valueOf(f).length > maxTextLength && !errors.containsKey(f)) {
        errors[f] = 'Too long (max $maxTextLength characters)';
      }
    }

    if (t.year.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(t.year)) {
      errors['year'] = 'Use a 4-digit year, e.g. 2019';
    }

    if (t.track.isNotEmpty) {
      final m = RegExp(r'^(\d{1,3})(?:/(\d{1,3}))?$').firstMatch(t.track);
      if (m == null) {
        errors['track'] = 'Use a number like 3, or 3/12';
      } else {
        final number = int.parse(m.group(1)!);
        final total = m.group(2) == null ? null : int.parse(m.group(2)!);
        if (number == 0) {
          errors['track'] = 'Track number must be 1 or more';
        } else if (total != null && total < number) {
          errors['track'] = 'Total can\'t be smaller than the track number';
        }
      }
    }
    return errors;
  }

  /// "2019", "2019-05-17" and "May 2019" all become "2019"; junk becomes ''.
  static String _cleanYear(String raw) {
    final m = RegExp(r'(?<!\d)(\d{4})(?!\d)').firstMatch(raw);
    return m?.group(1) ?? '';
  }

  @override
  bool operator ==(Object other) =>
      other is SongTags &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.albumArtist == albumArtist &&
      other.genre == genre &&
      other.year == year &&
      other.track == track;

  @override
  int get hashCode =>
      Object.hash(title, artist, album, albumArtist, genre, year, track);
}
