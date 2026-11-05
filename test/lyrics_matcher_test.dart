import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/features/lyrics/lyrics_matcher.dart';
import 'package:kanyoni/features/lyrics/lyrics_model.dart';

LyricsModel candidate(
  String title,
  String artist,
  double duration, {
  bool synced = true,
}) {
  return LyricsModel(
    id: 1,
    trackName: title,
    artistName: artist,
    albumName: '',
    duration: duration,
    instrumental: false,
    plainLyrics: 'la la la',
    syncedLyrics: synced ? '[00:01.00] la la la' : '',
  );
}

void main() {
  group('cleanTitle', () {
    test('removes extension and track number', () {
      expect(
        LyricsMatcher.cleanTitle('01 - Blinding Lights.mp3'),
        equals('Blinding Lights'),
      );
      expect(LyricsMatcher.cleanTitle('07. Hello'), equals('Hello'));
    });

    test('removes noise in brackets but keeps real version info', () {
      expect(LyricsMatcher.cleanTitle('Song (Official Video)'), equals('Song'));
      expect(LyricsMatcher.cleanTitle('Song [Lyrics]'), equals('Song'));
      expect(LyricsMatcher.cleanTitle('Song (feat. Someone)'), equals('Song'));
      expect(LyricsMatcher.cleanTitle('Song (Live)'), equals('Song (Live)'));
    });

    test('removes remaster suffixes and feat. suffixes', () {
      expect(LyricsMatcher.cleanTitle('Song - 2011 Remaster'), equals('Song'));
      expect(LyricsMatcher.cleanTitle('Song - Radio Edit'), equals('Song'));
      expect(LyricsMatcher.cleanTitle('Song ft. Someone'), equals('Song'));
    });

    test('does not damage real titles that start with digits', () {
      expect(
        LyricsMatcher.cleanTitle('1-800-273-8255'),
        equals('1-800-273-8255'),
      );
      expect(LyricsMatcher.cleanTitle('99 Problems'), equals('99 Problems'));
      expect(LyricsMatcher.cleanTitle('7 Rings'), equals('7 Rings'));
    });

    test('stripAllBrackets drops every bracketed part', () {
      expect(
        LyricsMatcher.stripAllBrackets('Song (Live at Wembley)'),
        equals('Song'),
      );
    });
  });

  group('artists', () {
    test('unknown artists become empty', () {
      expect(LyricsMatcher.cleanArtist('<unknown>'), equals(''));
      expect(LyricsMatcher.cleanArtist('Unknown Artist'), equals(''));
    });

    test('primaryArtist splits credits but not band names', () {
      expect(
        LyricsMatcher.primaryArtist('Drake feat. Rihanna'),
        equals('Drake'),
      );
      expect(
        LyricsMatcher.primaryArtist('Artist A, Artist B'),
        equals('Artist A'),
      );
      expect(
        LyricsMatcher.primaryArtist('Simon & Garfunkel'),
        equals('Simon & Garfunkel'),
      );
      expect(LyricsMatcher.primaryArtist('AC/DC'), equals('AC/DC'));
    });

    test('Topic channel suffix is removed', () {
      expect(LyricsMatcher.cleanArtist('Adele - Topic'), equals('Adele'));
    });
  });

  group('parseFileName / variants', () {
    test('parses Artist - Title', () {
      final r = LyricsMatcher.parseFileName('Adele - Hello.mp3')!;
      expect(r.artist, equals('Adele'));
      expect(r.title, equals('Hello'));
      expect(LyricsMatcher.parseFileName('JustATitle'), isNull);
    });

    test('title tag containing "Artist - Title" is split', () {
      const q = LyricsQuery(title: 'Adele - Hello', artist: 'Adele');
      expect(LyricsMatcher.titleVariants(q), contains('Hello'));
    });

    test('file name is used when tags are missing', () {
      const q = LyricsQuery(
        title: '<unknown>',
        artist: '<unknown>',
        fileName: 'Adele - Hello',
      );
      expect(LyricsMatcher.titleVariants(q), equals(['Hello']));
      expect(LyricsMatcher.artistVariants(q), equals(['Adele']));
    });

    test('variants are de-duplicated', () {
      const q = LyricsQuery(title: 'Hello', artist: 'Adele');
      expect(LyricsMatcher.titleVariants(q), equals(['Hello']));
      expect(LyricsMatcher.artistVariants(q), equals(['Adele']));
    });
  });

  group('similarity', () {
    test('ignores case, accents and punctuation', () {
      expect(LyricsMatcher.similarity('Beyoncé', 'beyonce'), equals(1));
      expect(LyricsMatcher.similarity("Don't Stop", 'dont stop'), equals(1));
      expect(
        LyricsMatcher.similarity('Rock & Roll', 'Rock and Roll'),
        equals(1),
      );
    });

    test('unrelated strings score low', () {
      expect(LyricsMatcher.similarity('Hello', 'Goodbye') < 0.3, isTrue);
    });
  });

  group('pickBest', () {
    const q = LyricsQuery(
      title: 'Hello',
      artist: 'Adele',
      album: '25',
      durationSec: 295,
    );

    test('prefers the result whose duration is closest', () {
      final best = LyricsMatcher.pickBest([
        candidate('Hello', 'Adele', 301),
        candidate('Hello', 'Adele', 295.4),
        candidate('Hello', 'Adele', 298),
      ], q)!;
      expect(best.duration, equals(295.4));
    });

    test('rejects a recording of a very different length', () {
      expect(
        LyricsMatcher.pickBest([candidate('Hello', 'Adele', 240)], q),
        isNull,
      );
    });

    test('rejects a different song that shares a word', () {
      expect(
        LyricsMatcher.pickBest([
          candidate('Hello Goodbye', 'The Beatles', 295),
        ], q),
        isNull,
      );
    });

    test('rejects a cover by another artist with a similar length', () {
      expect(
        LyricsMatcher.pickBest([candidate('Hello', 'Some Cover Band', 292)], q),
        isNull,
      );
    });

    test(
      'accepts a different artist credit when title and length are exact',
      () {
        final best = LyricsMatcher.pickBest([
          candidate('Hello', 'Adele Laurie Blue Adkins', 295),
        ], q);
        expect(best, isNotNull);
      },
    );

    test('prefers synced lyrics over plain when otherwise equal', () {
      final best = LyricsMatcher.pickBest([
        candidate('Hello', 'Adele', 295, synced: false),
        candidate('Hello', 'Adele', 295, synced: true),
      ], q)!;
      expect(best.hasSynced, isTrue);
    });

    test('works when the song length is unknown', () {
      const noDuration = LyricsQuery(title: 'Hello', artist: 'Adele');
      expect(
        LyricsMatcher.pickBest([candidate('Hello', 'Adele', 295)], noDuration),
        isNotNull,
      );
    });

    test('matches through cleaned-up tags', () {
      const dirty = LyricsQuery(
        title: '03 - Hello (Official Video)',
        artist: 'Adele - Topic',
        durationSec: 295,
      );
      expect(
        LyricsMatcher.pickBest([candidate('Hello', 'Adele', 295)], dirty),
        isNotNull,
      );
    });

    test('ignores results with no lyrics at all', () {
      final empty = LyricsModel(
        id: 2,
        trackName: 'Hello',
        artistName: 'Adele',
        albumName: '',
        duration: 295,
        instrumental: false,
        plainLyrics: '',
        syncedLyrics: '',
      );
      expect(LyricsMatcher.pickBest([empty], q), isNull);
    });
  });
}
