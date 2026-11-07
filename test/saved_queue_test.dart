import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/utils/helpers/saved_queue.dart';

Map<int, String> library(List<int> ids) => {for (final i in ids) i: 's$i'};

void main() {
  group('SavedQueue encode/decode', () {
    test('survives a round trip, including shuffle state', () {
      const q = SavedQueue(
        ids: [5, 3, 9],
        originalIds: [3, 5, 9],
        currentIndex: 1,
        currentId: 3,
        shuffle: true,
      );
      final back = SavedQueue.decode(q.encode())!;
      expect(back.ids, equals([5, 3, 9]));
      expect(back.originalIds, equals([3, 5, 9]));
      expect(back.currentIndex, equals(1));
      expect(back.currentId, equals(3));
      expect(back.shuffle, isTrue);
    });

    test('an unshuffled queue has no original order', () {
      const q = SavedQueue(ids: [1, 2], currentIndex: 0, currentId: 1);
      final back = SavedQueue.decode(q.encode())!;
      expect(back.originalIds, isNull);
      expect(back.shuffle, isFalse);
    });

    test('garbage, empty and wrong-version data decode to null', () {
      expect(SavedQueue.decode(null), isNull);
      expect(SavedQueue.decode(''), isNull);
      expect(SavedQueue.decode('not json'), isNull);
      expect(SavedQueue.decode('{"v": 99, "ids": [1]}'), isNull);
      expect(SavedQueue.decode('{"v": 1, "ids": []}'), isNull);
      expect(SavedQueue.decode('{"v": 1, "ids": ["a"]}'), isNull);
    });
  });

  group('SavedQueue.resolve', () {
    test('restores the exact order and the playing song', () {
      const q = SavedQueue(ids: [7, 2, 9, 4], currentIndex: 2, currentId: 9);
      final r = q.resolve(library([2, 4, 7, 9]))!;
      expect(r.items, equals(['s7', 's2', 's9', 's4']));
      expect(r.current, equals(2));
      expect(r.items[r.current], equals('s9'));
    });

    test('a shuffled queue stays shuffled and keeps its original order', () {
      const q = SavedQueue(
        ids: [3, 1, 2],
        originalIds: [1, 2, 3],
        currentIndex: 0,
        currentId: 3,
        shuffle: true,
      );
      final r = q.resolve(library([1, 2, 3]))!;
      expect(r.items, equals(['s3', 's1', 's2']));
      expect(r.original, equals(['s1', 's2', 's3']));
    });

    test('deleted songs before the playing one shift the index', () {
      const q = SavedQueue(ids: [1, 2, 3, 4], currentIndex: 3, currentId: 4);
      final r = q.resolve(library([2, 4]))!; // 1 and 3 are gone
      expect(r.items, equals(['s2', 's4']));
      expect(r.items[r.current], equals('s4'));
    });

    test(
      'if the playing song was deleted, the next surviving one is current',
      () {
        const q = SavedQueue(ids: [1, 2, 3, 4], currentIndex: 1, currentId: 2);
        final r = q.resolve(library([1, 3, 4]))!;
        expect(r.items, equals(['s1', 's3', 's4']));
        expect(r.items[r.current], equals('s3'));
      },
    );

    test(
      'if the playing song was last and deleted, current is the new last',
      () {
        const q = SavedQueue(ids: [1, 2, 3], currentIndex: 2, currentId: 3);
        final r = q.resolve(library([1, 2]))!;
        expect(r.current, equals(1));
        expect(r.items[r.current], equals('s2'));
      },
    );

    test('a stale index is corrected using the remembered song id', () {
      const q = SavedQueue(ids: [10, 20, 30], currentIndex: 0, currentId: 30);
      final r = q.resolve(library([10, 20, 30]))!;
      expect(r.items[r.current], equals('s30'));
    });

    test('an out-of-range index is clamped instead of crashing', () {
      const q = SavedQueue(ids: [1, 2], currentIndex: 50);
      final r = q.resolve(library([1, 2]))!;
      expect(r.current, equals(1));
    });

    test('nothing surviving gives null', () {
      const q = SavedQueue(ids: [1, 2], currentIndex: 0, currentId: 1);
      expect(q.resolve(library([9])), isNull);
    });

    test('songs missing from the original order are dropped there too', () {
      const q = SavedQueue(
        ids: [2, 1],
        originalIds: [1, 2, 3],
        currentIndex: 0,
        currentId: 2,
        shuffle: true,
      );
      final r = q.resolve(library([1, 2]))!;
      expect(r.original, equals(['s1', 's2']));
    });

    test('duplicates of a song in the queue are preserved', () {
      const q = SavedQueue(ids: [1, 2, 1], currentIndex: 2, currentId: 1);
      final r = q.resolve(library([1, 2]))!;
      expect(r.items, equals(['s1', 's2', 's1']));
      expect(r.current, equals(2));
    });
  });
}
