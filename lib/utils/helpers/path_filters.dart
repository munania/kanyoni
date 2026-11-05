/// Pure-Dart helpers for deciding which songs should be hidden.
///
/// Kept free of Flutter/GetX imports so they can be unit tested.
library;

/// Returns [folder] with exactly one trailing '/' so that prefix checks only
/// match whole directory names ("/Music/Rock/" no longer matches
/// "/Music/Rockabilly/song.mp3").
String withTrailingSlash(String folder) {
  final trimmed = folder.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.endsWith('/') ? trimmed : '$trimmed/';
}

/// True when [filePath] lives inside (or below) any of [blacklistedFolders].
bool isInBlacklistedFolder(
  String filePath,
  Iterable<String> blacklistedFolders,
) {
  for (final folder in blacklistedFolders) {
    final normalized = withTrailingSlash(folder);
    if (normalized.isEmpty) continue;
    if (filePath.startsWith(normalized)) return true;
  }
  return false;
}

/// True when a song should be dropped for being shorter than [minLengthSeconds].
/// Songs with an unknown duration are kept, since we can't tell.
bool isTooShort(int? durationMs, int minLengthSeconds) {
  if (minLengthSeconds <= 0 || durationMs == null) return false;
  return durationMs < minLengthSeconds * 1000;
}
