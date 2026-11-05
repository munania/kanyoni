import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/features/equalizer/eq_math.dart';

bool strictlyIncreasing(List<double> v) {
  for (var i = 1; i < v.length; i++) {
    if (v[i] <= v[i - 1]) return false;
  }
  return true;
}

void main() {
  presetStorageTests();
  group('EqBands', () {
    test('layouts have the right size and increase in frequency', () {
      for (final n in EqBands.supportedCounts) {
        final f = EqBands.forCount(n);
        expect(f.length, equals(n));
        expect(strictlyIncreasing(f), isTrue);
      }
    });

    test('unsupported counts are rejected', () {
      var threw = false;
      try {
        EqBands.forCount(7);
      } catch (_) {
        threw = true;
      }
      expect(threw, isTrue);
    });

    test('band edges are increasing, above each centre and within 20 kHz', () {
      for (final n in EqBands.supportedCounts) {
        final centers = EqBands.forCount(n);
        final edges = EqBands.upperEdges(centers);
        expect(edges.length, equals(n));
        expect(strictlyIncreasing(edges), isTrue);
        for (var i = 0; i < n; i++) {
          expect(edges[i] >= centers[i], isTrue);
        }
        expect(edges.last <= 20000, isTrue);
      }
    });
  });

  group('EqMath rounding and formatting', () {
    test('rounds to 0.1 dB and never produces negative zero', () {
      expect(EqMath.round(3.14159), equals(3.1));
      expect(EqMath.round(-0.04), equals(0.0));
      expect(EqMath.round(2.25), equals(2.3));
    });

    test('clamp keeps values inside the range', () {
      expect(EqMath.clamp(20, -12, 12), equals(12));
      expect(EqMath.clamp(-20, -12, 12), equals(-12));
      expect(EqMath.clamp(3, -12, 12), equals(3));
    });

    test('formats frequencies and gains for display', () {
      expect(EqMath.formatFrequency(31.5), equals('31.5'));
      expect(EqMath.formatFrequency(125), equals('125'));
      expect(EqMath.formatFrequency(1000), equals('1k'));
      expect(EqMath.formatFrequency(12500), equals('12.5k'));
      expect(EqMath.formatDb(3.5), equals('+3.5'));
      expect(EqMath.formatDb(0), equals('0.0'));
      expect(EqMath.formatDb(-2), equals('-2.0'));
    });
  });

  group('curve maths', () {
    test('interpolation passes through control points', () {
      final xs = [100.0, 1000.0, 10000.0];
      final ys = [0.0, 6.0, -3.0];
      expect(EqMath.interpolateLog(xs, ys, 100), equals(0.0));
      expect(EqMath.interpolateLog(xs, ys, 1000), equals(6.0));
      expect(EqMath.interpolateLog(xs, ys, 10000), equals(-3.0));
    });

    test('is linear in log-frequency (midpoint in octaves)', () {
      // sqrt(100*1000) is halfway between them on a log axis.
      final mid = EqMath.interpolateLog([100.0, 1000.0], [0.0, 6.0], 316.2278);
      expect((mid - 3.0).abs() < 0.01, isTrue);
    });

    test('values outside the range hold the end values', () {
      final xs = [100.0, 1000.0];
      final ys = [2.0, 4.0];
      expect(EqMath.interpolateLog(xs, ys, 20), equals(2.0));
      expect(EqMath.interpolateLog(xs, ys, 20000), equals(4.0));
    });

    test('resampling a flat curve stays flat', () {
      final out = EqMath.resample(
        EqBands.tenBand,
        List.filled(10, 0.0),
        EqBands.thirtyOneBand,
      );
      expect(out.length, equals(31));
      expect(out.every((g) => g == 0.0), isTrue);
    });

    test('resampling keeps the shape when going 10 -> 31 bands', () {
      final ten = [for (var i = 0; i < 10; i++) i.toDouble()]; // rising ramp
      final out = EqMath.resample(EqBands.tenBand, ten, EqBands.thirtyOneBand);
      for (var i = 1; i < out.length; i++) {
        expect(out[i] >= out[i - 1], isTrue); // still monotonic
      }
      expect(out.first, equals(0.0));
      expect(out.last, equals(9.0));
    });

    test('smooth response hits every band gain exactly', () {
      final c = EqBands.tenBand;
      final g = [0.0, 2.0, -1.0, 3.0, 0.0, 4.0, -2.0, 1.0, 0.0, 5.0];
      for (var i = 0; i < c.length; i++) {
        expect((EqMath.responseDb(c[i], c, g) - g[i]).abs() < 1e-9, isTrue);
      }
    });

    test('suggested preamp is minus the largest boost, never positive', () {
      expect(EqMath.suggestedPreamp([1, 4.5, -3]), equals(-4.5));
      expect(EqMath.suggestedPreamp([-1, -2]), equals(0.0));
    });
  });

  group('EqPresets', () {
    test('every built-in produces gains for every layout within +/-12 dB', () {
      for (final name in EqPresets.names) {
        for (final n in EqBands.supportedCounts) {
          final gains = EqPresets.gainsFor(name, EqBands.forCount(n))!;
          expect(gains.length, equals(n));
          expect(gains.every((g) => g >= -12 && g <= 12), isTrue);
        }
      }
    });

    test('Flat is all zeros and unknown names return null', () {
      expect(
        EqPresets.gainsFor('Flat', EqBands.tenBand)!.every((g) => g == 0),
        isTrue,
      );
      expect(EqPresets.gainsFor('Nope', EqBands.tenBand), isNull);
    });

    test('Bass Boost lifts lows more than highs', () {
      final g = EqPresets.gainsFor('Bass Boost', EqBands.tenBand)!;
      expect(g.first > g.last, isTrue);
      expect(g.first > 0, isTrue);
    });

    test('the same preset has a similar shape on 10 and 31 bands', () {
      final ten = EqPresets.gainsFor('Rock', EqBands.tenBand)!;
      final thirtyOne = EqPresets.gainsFor('Rock', EqBands.thirtyOneBand)!;
      // 1 kHz is band 5 on the 10-band layout and band 17 on the 31-band one.
      expect((ten[5] - thirtyOne[17]).abs() < 0.11, isTrue);
    });
  });
}

void presetStorageTests() {
  group('CustomPreset', () {
    test('survives a save/load round trip', () {
      final original = {
        'My Mix': CustomPreset(
          name: 'My Mix',
          freqs: EqBands.tenBand,
          gains: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        ),
      };
      final loaded = CustomPreset.decodeAll(CustomPreset.encodeAll(original));
      expect(loaded.length, equals(1));
      expect(loaded['My Mix']!.gains[9], equals(10.0));
      expect(loaded['My Mix']!.freqs.length, equals(10));
    });

    test('bad data gives an empty map instead of crashing', () {
      expect(CustomPreset.decodeAll('not json').isEmpty, isTrue);
      expect(CustomPreset.decodeAll(null).isEmpty, isTrue);
      expect(
        CustomPreset.decodeAll('{"x": {"f": [1], "g": []}}').isEmpty,
        isTrue,
      );
    });

    test('is re-sampled onto a different band layout', () {
      final preset = CustomPreset(
        name: 'Ramp',
        freqs: EqBands.tenBand,
        gains: [for (var i = 0; i < 10; i++) i.toDouble()],
      );
      final on31 = preset.gainsFor(EqBands.thirtyOneBand);
      expect(on31.length, equals(31));
      expect(on31.first, equals(0.0));
      expect(on31.last, equals(9.0));
      expect(preset.gainsFor(EqBands.tenBand)[4], equals(4.0));
    });
  });
}
