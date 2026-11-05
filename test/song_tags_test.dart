import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/features/tag_editor/song_tags.dart';

void main() {
  group('SongTags.changesFrom', () {
    const original = SongTags(
      title: 'Hello',
      artist: 'Adele',
      album: '25',
      year: '2015',
      track: '1',
    );

    test('no edits means no changes', () {
      expect(original.changesFrom(original).isEmpty, isTrue);
    });

    test('only the edited fields are reported', () {
      final edited = original.copyWith(title: 'Hello (Live)', genre: 'Pop');
      final changes = edited.changesFrom(original);
      expect(changes.length, equals(2));
      expect(changes['title'], equals('Hello (Live)'));
      expect(changes['genre'], equals('Pop'));
    });

    test('whitespace-only differences are not changes', () {
      final edited = original.copyWith(title: '  Hello  ', artist: 'Adele ');
      expect(edited.changesFrom(original).isEmpty, isTrue);
    });

    test('clearing a field is reported as an empty string', () {
      final changes = original.copyWith(album: '').changesFrom(original);
      expect(changes['album'], equals(''));
      expect(changes.length, equals(1));
    });
  });

  group('SongTags.validate', () {
    test('a normal set of tags is valid', () {
      const t = SongTags(
        title: 'Song',
        artist: 'A',
        year: '2020',
        track: '3/12',
      );
      expect(t.validate().isEmpty, isTrue);
    });

    test('title is required', () {
      expect(
        const SongTags(title: '  ').validate().containsKey('title'),
        isTrue,
      );
    });

    test('year must be four digits or empty', () {
      expect(
        const SongTags(title: 'x', year: '20').validate()['year'],
        isNotNull,
      );
      expect(
        const SongTags(title: 'x', year: 'abcd').validate()['year'],
        isNotNull,
      );
      expect(const SongTags(title: 'x', year: '').validate().isEmpty, isTrue);
    });

    test('track accepts 3 and 3/12 but nothing else', () {
      expect(const SongTags(title: 'x', track: '3').validate().isEmpty, isTrue);
      expect(
        const SongTags(title: 'x', track: '3/12').validate().isEmpty,
        isTrue,
      );
      expect(
        const SongTags(title: 'x', track: 'three').validate()['track'],
        isNotNull,
      );
      expect(
        const SongTags(title: 'x', track: '0').validate()['track'],
        isNotNull,
      );
      expect(
        const SongTags(title: 'x', track: '5/3').validate()['track'],
        isNotNull,
      );
    });

    test('overly long text is rejected', () {
      final t = SongTags(title: 'x' * 300);
      expect(t.validate()['title'], isNotNull);
    });
  });

  group('SongTags.fromMap', () {
    test('reads strings, trims them and tolerates nulls', () {
      final t = SongTags.fromMap({'title': ' A ', 'artist': null, 'album': 5});
      expect(t.title, equals('A'));
      expect(t.artist, equals(''));
      expect(t.album, equals(''));
    });

    test('normalises years that come back as full dates', () {
      expect(SongTags.fromMap({'year': '2019-05-17'}).year, equals('2019'));
      expect(SongTags.fromMap({'year': 'May 2019'}).year, equals('2019'));
      expect(SongTags.fromMap({'year': '0'}).year, equals(''));
      expect(SongTags.fromMap(null).year, equals(''));
    });
  });

  group('isEditableExtension', () {
    test('accepts supported types in any case, with or without a dot', () {
      expect(isEditableExtension('mp3'), isTrue);
      expect(isEditableExtension('.FLAC'), isTrue);
      expect(isEditableExtension('M4A'), isTrue);
    });

    test('rejects others', () {
      expect(isEditableExtension('wav'), isFalse);
      expect(isEditableExtension('aac'), isFalse);
      expect(isEditableExtension(null), isFalse);
    });
  });
}
