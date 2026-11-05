class LyricsModel {
  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final double duration;
  final bool instrumental;
  final String plainLyrics;
  final String syncedLyrics;

  LyricsModel({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.instrumental,
    required this.plainLyrics,
    required this.syncedLyrics,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    return LyricsModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String? ?? '',
      duration: (json['duration'] as num?)?.toDouble() ?? 0,
      instrumental: json['instrumental'] as bool? ?? false,
      plainLyrics: json['plainLyrics'] as String? ?? '',
      syncedLyrics: json['syncedLyrics'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'duration': duration,
      'instrumental': instrumental,
      'plainLyrics': plainLyrics,
      'syncedLyrics': syncedLyrics,
    };
  }

  bool get hasSynced => syncedLyrics.trim().isNotEmpty;
  bool get hasAnyText => hasSynced || plainLyrics.trim().isNotEmpty;
}

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}
