/// Result of an operation on a play queue.
class QueueResult<T> {
  final List<T> items;

  /// Index of the current song in [items], or -1 when the queue is empty.
  final int currentIndex;

  /// True when the song that was playing is no longer in the queue. The
  /// caller must then load [currentIndex] (the song that took its place).
  final bool currentRemoved;

  const QueueResult(
    this.items,
    this.currentIndex, {
    this.currentRemoved = false,
  });
}

/// Pure queue maths: how the list and the "now playing" index change when
/// songs are added, removed or reordered. Playback side effects stay in
/// PlayerController; keeping the index arithmetic here makes it testable.
class QueueOps {
  QueueOps._();

  /// Appends [added] at the end. The current song doesn't change.
  static QueueResult<T> append<T>(List<T> items, int current, List<T> added) {
    final out = [...items, ...added];
    return QueueResult(out, out.isEmpty ? -1 : (current < 0 ? 0 : current));
  }

  /// Inserts [added] directly after the current song ("play next").
  static QueueResult<T> insertAfterCurrent<T>(
    List<T> items,
    int current,
    List<T> added,
  ) {
    final at = (current < 0 || current >= items.length)
        ? items.length
        : current + 1;
    final out = [...items.sublist(0, at), ...added, ...items.sublist(at)];
    return QueueResult(out, out.isEmpty ? -1 : (current < 0 ? 0 : current));
  }

  /// Removes the songs at [indices] (invalid indices are ignored).
  ///
  /// * If the current song is not removed, the index follows it.
  /// * If it is removed, [QueueResult.currentIndex] points at the song that
  ///   slid into its place (or the new last song when it was the last).
  static QueueResult<T> removeIndices<T>(
    List<T> items,
    int current,
    Iterable<int> indices,
  ) {
    final remove = indices.where((i) => i >= 0 && i < items.length).toSet();
    if (remove.isEmpty) {
      return QueueResult(List<T>.from(items), current);
    }

    final kept = <T>[];
    var removedBeforeCurrent = 0;
    for (var i = 0; i < items.length; i++) {
      if (remove.contains(i)) {
        if (i < current) removedBeforeCurrent++;
      } else {
        kept.add(items[i]);
      }
    }

    if (kept.isEmpty) {
      return QueueResult(kept, -1, currentRemoved: remove.contains(current));
    }

    final currentRemoved = remove.contains(current);
    var newCurrent = current - removedBeforeCurrent;
    if (newCurrent >= kept.length) newCurrent = kept.length - 1;
    if (newCurrent < 0) newCurrent = 0;
    return QueueResult(kept, newCurrent, currentRemoved: currentRemoved);
  }

  /// Moves one song, using the indices exactly as Flutter's
  /// ReorderableListView reports them (the new index is "before removal").
  static QueueResult<T> move<T>(
    List<T> items,
    int current,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < 0 || oldIndex >= items.length) {
      return QueueResult(List<T>.from(items), current);
    }
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    target = target.clamp(0, items.length - 1);
    if (target == oldIndex) return QueueResult(List<T>.from(items), current);

    final out = List<T>.from(items);
    final moved = out.removeAt(oldIndex);
    out.insert(target, moved);

    var newCurrent = current;
    if (current == oldIndex) {
      newCurrent = target;
    } else if (oldIndex < current && target >= current) {
      newCurrent = current - 1;
    } else if (oldIndex > current && target <= current) {
      newCurrent = current + 1;
    }
    return QueueResult(out, newCurrent);
  }
}
