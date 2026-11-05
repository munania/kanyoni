import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/features/playlists/playlist_logic.dart';
import 'package:kanyoni/utils/helpers/queue_ops.dart';

void main() {
  group('QueueOps.append / insertAfterCurrent', () {
    test('append adds to the end and keeps the current song', () {
      final r = QueueOps.append(['a', 'b', 'c'], 1, ['x', 'y']);
      expect(r.items, equals(['a', 'b', 'c', 'x', 'y']));
      expect(r.currentIndex, equals(1));
    });

    test('play next inserts right after the current song', () {
      final r = QueueOps.insertAfterCurrent(['a', 'b', 'c'], 1, ['x', 'y']);
      expect(r.items, equals(['a', 'b', 'x', 'y', 'c']));
      expect(r.currentIndex, equals(1));
    });

    test('play next with nothing playing goes to the end', () {
      final r = QueueOps.insertAfterCurrent(['a', 'b'], -1, ['x']);
      expect(r.items, equals(['a', 'b', 'x']));
    });

    test('adding to an empty queue selects the first song', () {
      expect(QueueOps.append(<String>[], -1, ['x']).currentIndex, equals(0));
    });
  });

  group('QueueOps.removeIndices', () {
    test('removing a song before the current one shifts the index', () {
      final r = QueueOps.removeIndices(['a', 'b', 'c', 'd'], 2, [0]);
      expect(r.items, equals(['b', 'c', 'd']));
      expect(r.currentIndex, equals(1)); // still "c"
      expect(r.currentRemoved, isFalse);
    });

    test('removing a song after the current one leaves the index alone', () {
      final r = QueueOps.removeIndices(['a', 'b', 'c', 'd'], 1, [3]);
      expect(r.items, equals(['a', 'b', 'c']));
      expect(r.currentIndex, equals(1));
      expect(r.currentRemoved, isFalse);
    });

    test(
      'removing the current song points at the one that slid into place',
      () {
        final r = QueueOps.removeIndices(['a', 'b', 'c', 'd'], 1, [1]);
        expect(r.items, equals(['a', 'c', 'd']));
        expect(r.currentIndex, equals(1)); // now "c"
        expect(r.currentRemoved, isTrue);
      },
    );

    test('removing the current last song moves back to the new last', () {
      final r = QueueOps.removeIndices(['a', 'b', 'c'], 2, [2]);
      expect(r.items, equals(['a', 'b']));
      expect(r.currentIndex, equals(1));
      expect(r.currentRemoved, isTrue);
    });

    test('removing several songs at once, around the current one', () {
      final r = QueueOps.removeIndices(['a', 'b', 'c', 'd', 'e'], 3, [0, 1, 4]);
      expect(r.items, equals(['c', 'd']));
      expect(r.currentIndex, equals(1)); // still "d"
      expect(r.currentRemoved, isFalse);
    });

    test('removing everything empties the queue', () {
      final r = QueueOps.removeIndices(['a', 'b'], 0, [0, 1]);
      expect(r.items.isEmpty, isTrue);
      expect(r.currentIndex, equals(-1));
      expect(r.currentRemoved, isTrue);
    });

    test('invalid indices are ignored', () {
      final r = QueueOps.removeIndices(['a', 'b'], 0, [-1, 7]);
      expect(r.items, equals(['a', 'b']));
      expect(r.currentIndex, equals(0));
    });
  });

  group('QueueOps.move', () {
    // ReorderableListView reports newIndex "before removal".
    test('moving the current song down keeps it current', () {
      final r = QueueOps.move(['a', 'b', 'c', 'd'], 0, 0, 3);
      expect(r.items, equals(['b', 'c', 'a', 'd']));
      expect(r.currentIndex, equals(2));
    });

    test('moving a later song before the current one shifts current down', () {
      final r = QueueOps.move(['a', 'b', 'c', 'd'], 1, 3, 0);
      expect(r.items, equals(['d', 'a', 'b', 'c']));
      expect(r.currentIndex, equals(2)); // "b" is now at 2
    });

    test('moving an earlier song after the current one shifts current up', () {
      final r = QueueOps.move(['a', 'b', 'c', 'd'], 2, 0, 4);
      expect(r.items, equals(['b', 'c', 'd', 'a']));
      expect(r.currentIndex, equals(1)); // "c" is now at 1
    });

    test('moving within the same slot changes nothing', () {
      final r = QueueOps.move(['a', 'b', 'c'], 1, 1, 2);
      expect(r.items, equals(['a', 'b', 'c']));
      expect(r.currentIndex, equals(1));
    });
  });

  group('LibraryIndex.matchEntries', () {
    SongIdentity s(
      int id,
      String path,
      String title, {
      String artist = 'A',
      int duration = 1000,
    }) => SongIdentity(
      id: id,
      path: path,
      title: title,
      artist: artist,
      duration: duration,
    );

    test('the file path decides, even when other songs share the tags', () {
      final lib = LibraryIndex([
        s(1, '/m/a.mp3', 'Same'),
        s(2, '/m/b.mp3', 'Same'), // a copy with identical tags
      ]);
      final out = lib.matchEntries([
        s(900, '/m/b.mp3', 'Same'),
        s(901, '/m/a.mp3', 'Same'),
      ]);
      expect(out, equals([1, 0]));
    });

    test('without a path, identical-tag songs are not collapsed into one', () {
      final lib = LibraryIndex([
        s(1, '/m/a.mp3', 'Same'),
        s(2, '/m/b.mp3', 'Same'),
      ]);
      final out = lib.matchEntries([s(900, '', 'Same'), s(901, '', 'Same')]);
      expect(out[0] != out[1], isTrue);
    });

    test('songs missing from the library give null', () {
      final lib = LibraryIndex([s(1, '/m/a.mp3', 'A')]);
      expect(lib.matchEntries([s(900, '/gone.mp3', 'Gone')]), equals([null]));
    });

    test('metadata matching ignores case and spacing', () {
      final lib = LibraryIndex([s(1, '/m/a.mp3', 'Hello', artist: 'Adele')]);
      final out = lib.matchEntries([s(900, '', ' hello ', artist: 'ADELE')]);
      expect(out, equals([0]));
    });
  });

  group('PlaylistNames', () {
    test('clean trims, collapses spaces and drops the app tag', () {
      expect(PlaylistNames.clean('  My   Mix [kanyoni] '), equals('My Mix'));
    });

    test('blank names are rejected', () {
      expect(PlaylistNames.validate('   ', const []), isNotNull);
      expect(PlaylistNames.validate('[kanyoni]', const []), isNotNull);
    });

    test('duplicates are rejected regardless of case and the tag', () {
      expect(PlaylistNames.validate('road trip', ['Road Trip']), isNotNull);
      expect(
        PlaylistNames.validate('Road Trip', ['Road Trip [kanyoni]']),
        isNotNull,
      );
    });

    test('a fresh, reasonable name is accepted', () {
      expect(PlaylistNames.validate('Gym', ['Road Trip']), isNull);
    });

    test('very long names are rejected', () {
      expect(PlaylistNames.validate('x' * 100, const []), isNotNull);
    });
  });
}
