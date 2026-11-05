import 'dart:convert';
import 'dart:math' as math;

/// Standard graphic-equalizer band layouts.
///
/// Pure Dart (no Flutter / platform imports) so everything here is unit
/// tested. The UI, the controller and the native engines all build on it.
class EqBands {
  EqBands._();

  /// The layouts the user can choose between.
  static const List<int> supportedCounts = [10, 15, 31];

  /// Octave layout (ISO centre frequencies).
  static const List<double> tenBand = [
    31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000, //
  ];

  /// Two-thirds octave layout.
  static const List<double> fifteenBand = [
    25, 40, 63, 100, 160, 250, 400, 630, 1000, 1600, 2500, 4000, 6300, 10000,
    16000, //
  ];

  /// One-third octave layout (the ISO standard for "pro" graphic EQs).
  static const List<double> thirtyOneBand = [
    20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630,
    800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000,
    12500, 16000, 20000, //
  ];

  /// Centre frequencies for [count] bands (10, 15 or 31).
  static List<double> forCount(int count) {
    switch (count) {
      case 10:
        return tenBand;
      case 15:
        return fifteenBand;
      case 31:
        return thirtyOneBand;
      default:
        throw ArgumentError.value(count, 'count', 'Unsupported band count');
    }
  }

  /// Upper edge of every band, in Hz: the geometric mean between neighbouring
  /// centres, so each band "owns" the range around its centre. The last edge
  /// is capped at [maxHz].
  static List<double> upperEdges(List<double> centers, {double maxHz = 20000}) {
    final n = centers.length;
    final edges = <double>[];
    for (var i = 0; i < n - 1; i++) {
      edges.add(math.sqrt(centers[i] * centers[i + 1]));
    }
    if (n == 0) return edges;
    final lastRatio = n >= 2 ? centers[n - 1] / centers[n - 2] : 2.0;
    final last = math.min(maxHz, centers[n - 1] * math.sqrt(lastRatio));
    // Never let the cap fall at or below the previous edge.
    edges.add(
      edges.isNotEmpty && last <= edges.last ? edges.last * 1.05 : last,
    );
    return edges;
  }
}

/// Maths for gains and curves.
class EqMath {
  EqMath._();

  /// Rounds [value] to [decimals] decimal places (0.1 dB steps by default).
  static double round(double value, {int decimals = 1}) {
    final factor = math.pow(10, decimals).toDouble();
    final rounded = (value * factor).round() / factor;
    // Avoid "-0.0" showing up in the UI.
    return rounded == 0 ? 0.0 : rounded;
  }

  static double clamp(double value, double minDb, double maxDb) =>
      value < minDb ? minDb : (value > maxDb ? maxDb : value);

  /// Linear interpolation of a curve defined by (x, y) points, but with the
  /// x axis in log scale - frequency is perceived logarithmically.
  /// Values outside the defined range are held at the end values.
  static double interpolateLog(List<double> xs, List<double> ys, double x) {
    if (xs.isEmpty) return 0;
    if (x <= xs.first) return ys.first;
    if (x >= xs.last) return ys.last;
    var i = 0;
    while (i < xs.length - 2 && x >= xs[i + 1]) {
      i++;
    }
    final x0 = math.log(xs[i]);
    final x1 = math.log(xs[i + 1]);
    final t = (math.log(x) - x0) / (x1 - x0);
    return ys[i] + (ys[i + 1] - ys[i]) * t;
  }

  /// Re-samples a curve onto another set of frequencies. Used when the user
  /// changes the band count (10 -> 31) so the *shape* is kept, and when a
  /// preset or saved curve has to fit a different layout.
  static List<double> resample(
    List<double> fromFreqs,
    List<double> fromGains,
    List<double> toFreqs,
  ) {
    return [
      for (final f in toFreqs) round(interpolateLog(fromFreqs, fromGains, f)),
    ];
  }

  /// Smooth curve used for drawing: cosine easing between band centres, so
  /// the preview has no sharp corners. Passes exactly through each band gain.
  static double responseDb(
    double hz,
    List<double> centers,
    List<double> gains,
  ) {
    if (centers.isEmpty) return 0;
    if (hz <= centers.first) return gains.first;
    if (hz >= centers.last) return gains.last;
    var i = 0;
    while (i < centers.length - 2 && hz >= centers[i + 1]) {
      i++;
    }
    final x0 = math.log(centers[i]);
    final x1 = math.log(centers[i + 1]);
    final t = (math.log(hz) - x0) / (x1 - x0);
    final eased = (1 - math.cos(math.pi * t)) / 2;
    return gains[i] + (gains[i + 1] - gains[i]) * eased;
  }

  /// Headroom compensation: a boost raises the peak level and can clip, so
  /// the preamp that fully avoids it is minus the largest boost.
  static double suggestedPreamp(List<double> gains) {
    var maxGain = 0.0;
    for (final g in gains) {
      if (g > maxGain) maxGain = g;
    }
    return round(-maxGain);
  }

  /// "31 Hz", "1k", "12.5k" - short labels for the narrow band columns.
  static String formatFrequency(double hz) {
    if (hz >= 1000) {
      final k = hz / 1000;
      final text = k == k.roundToDouble() ? k.toInt().toString() : k.toString();
      return '${text}k';
    }
    return hz == hz.roundToDouble() ? hz.toInt().toString() : hz.toString();
  }

  /// "+3.5", "0.0", "-2.0"
  static String formatDb(double db) {
    final v = round(db);
    final text = v.toStringAsFixed(1);
    return v > 0 ? '+$text' : text;
  }
}

/// Built-in presets, defined once as (Hz, dB) control points and then
/// resampled to whatever band layout is active. That way the same "Rock"
/// works for 10, 15 or 31 bands, and on the hardware's own band layout.
class EqPresets {
  EqPresets._();

  static const String flat = 'Flat';
  static const String custom = 'Custom';

  static const Map<String, List<(double, double)>> builtIn = {
    'Flat': [(20, 0), (20000, 0)],
    'Bass Boost': [(20, 6), (60, 6), (125, 4), (250, 2), (500, 0), (20000, 0)],
    'Bass Reducer': [
      (20, -6),
      (60, -5),
      (125, -3),
      (250, -1),
      (500, 0),
      (20000, 0),
    ],
    'Treble Boost': [
      (20, 0),
      (2000, 0),
      (4000, 2),
      (8000, 4.5),
      (16000, 6),
      (20000, 6),
    ],
    'Loudness': [
      (20, 5),
      (80, 4),
      (250, 0),
      (1000, -1),
      (3000, 0),
      (8000, 3.5),
      (16000, 5),
      (20000, 5),
    ],
    'Vocal': [
      (20, -3),
      (100, -2),
      (250, 0),
      (500, 1.5),
      (1000, 3),
      (2000, 3.5),
      (4000, 2),
      (8000, 0),
      (16000, -1.5),
      (20000, -1.5),
    ],
    'Rock': [
      (20, 4),
      (80, 3.5),
      (250, 1),
      (500, -1.5),
      (1000, -1),
      (3000, 1.5),
      (6000, 3),
      (12000, 4),
      (20000, 4),
    ],
    'Pop': [
      (20, -1),
      (80, 0),
      (250, 1.5),
      (1000, 3),
      (3000, 2.5),
      (8000, 0),
      (16000, -1),
      (20000, -1),
    ],
    'Jazz': [
      (20, 3),
      (100, 2.5),
      (250, 1),
      (500, 1.5),
      (1000, -1),
      (3000, 0),
      (8000, 2),
      (16000, 3),
      (20000, 3),
    ],
    'Classical': [
      (20, 3.5),
      (100, 3),
      (250, 2),
      (500, 0),
      (3000, 0),
      (6000, 2.5),
      (12000, 3),
      (20000, 3),
    ],
    'Electronic': [
      (20, 5),
      (60, 5),
      (125, 3),
      (250, 0),
      (500, -1.5),
      (1000, 0),
      (3000, 2),
      (8000, 3.5),
      (16000, 4.5),
      (20000, 4.5),
    ],
    'Hip-Hop': [
      (20, 6),
      (60, 5.5),
      (150, 3.5),
      (400, 0.5),
      (1000, 1.5),
      (3000, 0),
      (8000, 1),
      (16000, 2),
      (20000, 2),
    ],
    'Acoustic': [
      (20, 2),
      (100, 2.5),
      (250, 2),
      (500, 0.5),
      (2000, 1),
      (4000, 2),
      (8000, 2.5),
      (16000, 1.5),
      (20000, 1.5),
    ],
  };

  static List<String> get names => builtIn.keys.toList();

  static bool isBuiltIn(String name) => builtIn.containsKey(name);

  /// Gains of preset [name] for the band centres [freqs]; null if unknown.
  static List<double>? gainsFor(String name, List<double> freqs) {
    final points = builtIn[name];
    if (points == null) return null;
    final xs = [for (final p in points) p.$1];
    final ys = [for (final p in points) p.$2];
    return [
      for (final f in freqs) EqMath.round(EqMath.interpolateLog(xs, ys, f)),
    ];
  }
}

/// A preset the user saved. It stores the frequencies it was made for, so it
/// can be re-sampled onto any other band layout later.
class CustomPreset {
  final String name;
  final List<double> freqs;
  final List<double> gains;

  const CustomPreset({
    required this.name,
    required this.freqs,
    required this.gains,
  });

  /// This preset's curve for the band centres [target].
  List<double> gainsFor(List<double> target) {
    if (_sameFrequencies(freqs, target)) return List<double>.from(gains);
    return EqMath.resample(freqs, gains, target);
  }

  Map<String, dynamic> toJson() => {'f': freqs, 'g': gains};

  static CustomPreset? fromJson(String name, Object? json) {
    if (json is! Map) return null;
    final f = json['f'];
    final g = json['g'];
    if (f is! List || g is! List || f.isEmpty || f.length != g.length) {
      return null;
    }
    return CustomPreset(
      name: name,
      freqs: [for (final v in f) (v as num).toDouble()],
      gains: [for (final v in g) (v as num).toDouble()],
    );
  }

  /// Serialises a whole collection for SharedPreferences.
  static String encodeAll(Map<String, CustomPreset> presets) =>
      json.encode({for (final e in presets.entries) e.key: e.value.toJson()});

  /// Reads what [encodeAll] wrote; bad or missing data gives an empty map.
  static Map<String, CustomPreset> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return {};
      final out = <String, CustomPreset>{};
      for (final e in decoded.entries) {
        final preset = fromJson(e.key as String, e.value);
        if (preset != null) out[e.key as String] = preset;
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}

bool _sameFrequencies(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 0.01) return false;
  }
  return true;
}

/// Whether two frequency lists describe the same layout.
bool sameFrequencies(List<double> a, List<double> b) => _sameFrequencies(a, b);
