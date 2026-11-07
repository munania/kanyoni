import 'dart:convert';

/// A queue rebuilt from a [SavedQueue] against the current library.
class RestoredQueue<T> {
  final List<T> items;

  /// The un-shuffled order, when the queue was shuffled.
  final List<T>? original;

  /// Index of the song that was playing.
  final int current;

  const RestoredQueue(this.items, this.original, this.current);
}

/// What is remembered about the play queue between app launches: the exact
/// order (so a shuffled queue stays shuffled), the order before shuffling (so
/// turning shuffle off still works), which song was playing and whether
/// shuffle was on.
///
/// Songs are stored by id, so the snapshot stays small and survives tag edits.
/// Pure Dart: encoding and, importantly, [resolve] (what to do when songs have
/// been deleted since) are unit tested.
class SavedQueue {
  static const int version = 1;

  final List<int> ids;
  final List<int>? originalIds;
  final int currentIndex;

  /// Id of the song that was playing, or -1 if unknown. Used to find it again
  /// if [currentIndex] no longer lines up.
  final int currentId;
  final bool shuffle;

  const SavedQueue({
    required this.ids,
    this.originalIds,
    required this.currentIndex,
    this.currentId = -1,
    this.shuffle = false,
  });

  String encode() => json.encode({
    'v': version,
    'ids': ids,
    if (originalIds != null) 'orig': originalIds,
    'i': currentIndex,
    'c': currentId,
    's': shuffle,
  });

  /// Reads what [encode] wrote. Anything unreadable gives null (the app then
  /// falls back to its simple "last song" restore).
  static SavedQueue? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = json.decode(raw);
      if (map is! Map || map['v'] != version) return null;

      List<int>? ints(Object? value) {
        if (value is! List) return null;
        return [for (final v in value) (v as num).toInt()];
      }

      final ids = ints(map['ids']);
      if (ids == null || ids.isEmpty) return null;
      return SavedQueue(
        ids: ids,
        originalIds: ints(map['orig']),
        currentIndex: (map['i'] as num?)?.toInt() ?? 0,
        currentId: (map['c'] as num?)?.toInt() ?? -1,
        shuffle: map['s'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Rebuilds the queue from [library] (song id -> song). Songs that no
  /// longer exist are dropped. If the song that was playing is gone, the
  /// current position becomes the song that followed it.
  /// Null when nothing survives.
  RestoredQueue<T>? resolve<T>(Map<int, T> library) {
    // Find where the playing song was. Trust the index only when it still
    // points at the remembered song.
    var current = currentIndex;
    final indexIsValid =
        current >= 0 &&
        current < ids.length &&
        (currentId == -1 || ids[current] == currentId);
    if (!indexIsValid) {
      final byId = currentId == -1 ? -1 : ids.indexOf(currentId);
      current = byId != -1 ? byId : current.clamp(0, ids.length - 1).toInt();
    }

    final kept = <T>[];
    var keptBeforeCurrent = 0;
    for (var i = 0; i < ids.length; i++) {
      final song = library[ids[i]];
      if (song == null) continue;
      if (i < current) keptBeforeCurrent++;
      kept.add(song);
    }
    if (kept.isEmpty) return null;

    // If the current song survived, it sits right after the kept songs that
    // came before it; if not, the next surviving song takes that slot.
    var newCurrent = keptBeforeCurrent;
    if (newCurrent >= kept.length) newCurrent = kept.length - 1;

    List<T>? original;
    final orig = originalIds;
    if (orig != null) {
      original = [
        for (final id in orig)
          if (library[id] != null) library[id] as T,
      ];
      if (original.isEmpty) original = null;
    }
    return RestoredQueue<T>(kept, original, newCurrent);
  }
}
