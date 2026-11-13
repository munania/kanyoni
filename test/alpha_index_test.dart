import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/utils/helpers/alpha_index.dart';

void main() {
  group('AlphaIndex.bucketFor', () {
    test('plain names go under their first letter, any case', () {
      expect(AlphaIndex.bucketFor('Adele'), equals('A'));
      expect(AlphaIndex.bucketFor('zayn'), equals('Z'));
    });

    test('accents are ignored', () {
      expect(AlphaIndex.bucketFor('Émile Simon'), equals('E'));
      expect(AlphaIndex.bucketFor('Ångström'), equals('A'));
      expect(AlphaIndex.bucketFor('Ólafur Arnalds'), equals('O'));
      expect(AlphaIndex.bucketFor('Beyoncé'), equals('B'));
    });

    test('leading punctuation and spaces are skipped', () {
      expect(AlphaIndex.bucketFor('(Intro)'), equals('I'));
      expect(AlphaIndex.bucketFor("'Til Tuesday"), equals('T'));
      expect(AlphaIndex.bucketFor('  ...Baby One More Time'), equals('B'));
    });

    test('digits, other alphabets, unknown and empty go under #', () {
      expect(AlphaIndex.bucketFor('50 Cent'), equals('#'));
      expect(AlphaIndex.bucketFor('<unknown>'), equals('#'));
      expect(AlphaIndex.bucketFor('Unknown Artist'), equals('U'));
      expect(AlphaIndex.bucketFor('Ελλάδα'), equals('#'));
      expect(AlphaIndex.bucketFor('周杰伦'), equals('#'));
      expect(AlphaIndex.bucketFor(''), equals('#'));
      expect(AlphaIndex.bucketFor(null), equals('#'));
      expect(AlphaIndex.bucketFor('!!!'), equals('#'));
    });
  });

  group('AlphaIndex.compareNames', () {
    test('sorts ignoring case, accents and punctuation', () {
      final names = ['Zed', 'émile', 'Adele', '(Intro)', 'beyoncé', 'Émilie'];
      names.sort(AlphaIndex.compareNames);
      expect(
        names,
        equals(['Adele', 'beyoncé', 'émile', 'Émilie', '(Intro)', 'Zed']),
      );
    });

    test('# group comes first', () {
      final names = ['Bob', '50 Cent', 'Adele', '周杰伦'];
      names.sort(AlphaIndex.compareNames);
      expect(names.first == '50 Cent' || names.first == '周杰伦', isTrue);
      expect(names.last, equals('Bob'));
    });

    test('the order always agrees with the buckets (no letter reappears)', () {
      final names = [
        'Émile',
        'Eagle',
        'Ångström',
        'Abba',
        'Zebra',
        'zoo',
        '9 Lives',
        'Élan',
      ]..sort(AlphaIndex.compareNames);
      final buckets = names.map(AlphaIndex.bucketFor).toList();
      // Each bucket forms one contiguous run.
      final seen = <String>{};
      String? previous;
      for (final b in buckets) {
        if (b != previous) {
          expect(seen.contains(b), isFalse);
          seen.add(b);
        }
        previous = b;
      }
    });
  });

  group('AlphaIndex.firstIndexByBucket', () {
    test('records where each group first appears', () {
      final map = AlphaIndex.firstIndexByBucket([
        'Abba',
        'Adele',
        'Bob',
        'Bono',
        'Cher',
        '1999',
      ]);
      expect(map['A'], equals(0));
      expect(map['B'], equals(2));
      expect(map['C'], equals(4));
      expect(map['#'], equals(5));
      expect(map.containsKey('D'), isFalse);
    });

    test('works for a descending list too (first occurrence wins)', () {
      final map = AlphaIndex.firstIndexByBucket(['Zed', 'Bob', 'Bono', 'Abba']);
      expect(map['Z'], equals(0));
      expect(map['B'], equals(1));
      expect(map['A'], equals(3));
    });
  });

  group('AlphaIndex.resolve', () {
    test('a present letter resolves to itself', () {
      expect(AlphaIndex.resolve('B', ['A', 'B', 'D']), equals('B'));
    });

    test('a missing letter moves to the next present one', () {
      expect(AlphaIndex.resolve('C', ['A', 'B', 'D']), equals('D'));
    });

    test('past the last present letter falls back to the nearest before', () {
      expect(AlphaIndex.resolve('Z', ['A', 'B', 'D']), equals('D'));
    });

    test('nothing present gives null', () {
      expect(AlphaIndex.resolve('A', <String>[]), isNull);
    });
  });

  group('AlphaIndex.letterAtFraction', () {
    test('top is # and bottom is Z', () {
      expect(AlphaIndex.letterAtFraction(0), equals('#'));
      expect(AlphaIndex.letterAtFraction(1), equals('Z'));
    });

    test('out-of-range positions are clamped', () {
      expect(AlphaIndex.letterAtFraction(-0.5), equals('#'));
      expect(AlphaIndex.letterAtFraction(1.7), equals('Z'));
    });

    test('moves through every letter in order', () {
      final seen = <String>[];
      for (var i = 0; i < AlphaIndex.letters.length; i++) {
        seen.add(
          AlphaIndex.letterAtFraction((i + 0.5) / AlphaIndex.letters.length),
        );
      }
      expect(seen, equals(AlphaIndex.letters));
    });
  });
}
