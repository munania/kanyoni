import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'eq_math.dart';

/// Something that can apply equalizer settings to the audio session of the
/// player. Two implementations exist:
///
///  * [DynamicsEqEngine]: Android 9+ `DynamicsProcessing` through a native
///    bridge. Any number of bands, fractional dB, preamp and a limiter.
///  * [LegacyEqEngine]: the system `Equalizer` effect (via just_audio) for
///    devices that can't do the above. Fixed bands chosen by the hardware.
abstract class EqEngine {
  String get name;

  /// Can the number of bands be changed by the user?
  bool get canChangeBands;

  /// Does [setPreamp] do anything?
  bool get supportsPreamp;

  double get minDb;
  double get maxDb;

  /// The band centres this engine is actually running. For [LegacyEqEngine]
  /// these are dictated by the hardware and may differ from what was asked.
  List<double> get freqs;

  /// Starts (or restarts) the effect on [sessionId]. Returns false when this
  /// engine can't run on this device; the caller then tries the next one.
  Future<bool> start({
    required int sessionId,
    required List<double> freqs,
    required List<double> gains,
    required double preampDb,
    required bool enabled,
  });

  Future<void> setEnabled(bool enabled);

  /// Sets some bands: band index -> gain in dB.
  Future<void> setGains(Map<int, double> changes);

  Future<void> setPreamp(double db);

  Future<void> release();
}

/// Android 9+ multi-band equalizer (`android.media.audiofx.DynamicsProcessing`)
/// driven through the `kanyoni/equalizer` platform channel (see
/// `EqualizerHost.kt`).
class DynamicsEqEngine implements EqEngine {
  static const MethodChannel _channel = MethodChannel('kanyoni/equalizer');

  List<double> _freqs = const [];

  @override
  String get name => 'Multi-band (DynamicsProcessing)';

  @override
  bool get canChangeBands => true;

  @override
  bool get supportsPreamp => true;

  @override
  double get minDb => -15;

  @override
  double get maxDb => 15;

  @override
  List<double> get freqs => _freqs;

  @override
  Future<bool> start({
    required int sessionId,
    required List<double> freqs,
    required List<double> gains,
    required double preampDb,
    required bool enabled,
  }) async {
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      if (supported != true) return false;

      final ok = await _channel.invokeMethod<bool>('start', {
        'sessionId': sessionId,
        'edges': EqBands.upperEdges(freqs),
        'gains': [for (final g in gains) EqMath.clamp(g, minDb, maxDb)],
        'preampDb': preampDb,
        'enabled': enabled,
      });
      if (ok == true) {
        _freqs = List<double>.from(freqs);
        return true;
      }
      return false;
    } on MissingPluginException {
      return false; // not running on Android / native side not registered
    } on PlatformException catch (e) {
      if (kDebugMode) print('DynamicsEqEngine.start failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }

  @override
  Future<void> setGains(Map<int, double> changes) async {
    if (changes.isEmpty) return;
    await _channel.invokeMethod<void>('setGains', {
      'indices': changes.keys.toList(),
      'gains': [for (final g in changes.values) EqMath.clamp(g, minDb, maxDb)],
    });
  }

  @override
  Future<void> setPreamp(double db) async {
    await _channel.invokeMethod<void>('setPreamp', {'db': db});
  }

  @override
  Future<void> release() async {
    try {
      await _channel.invokeMethod<void>('release');
    } catch (_) {}
  }
}

/// Fallback: the stock Android `Equalizer` effect (normally ~5 bands).
class LegacyEqEngine implements EqEngine {
  final AndroidEqualizer? _equalizer;
  List<AndroidEqualizerBand> _bands = const [];
  List<double> _freqs = const [];
  double _min = -15;
  double _max = 15;

  LegacyEqEngine(this._equalizer);

  @override
  String get name => 'System equalizer';

  @override
  bool get canChangeBands => false;

  @override
  bool get supportsPreamp => false;

  @override
  double get minDb => _min;

  @override
  double get maxDb => _max;

  @override
  List<double> get freqs => _freqs;

  @override
  Future<bool> start({
    required int sessionId,
    required List<double> freqs,
    required List<double> gains,
    required double preampDb,
    required bool enabled,
  }) async {
    final equalizer = _equalizer;
    if (equalizer == null) return false;
    try {
      final parameters = await equalizer.parameters;
      _min = parameters.minDecibels;
      _max = parameters.maxDecibels;
      _bands = parameters.bands;
      _freqs = [for (final b in _bands) b.centerFrequency];
      await equalizer.setEnabled(enabled);
      return _bands.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('LegacyEqEngine.start failed: $e');
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await _equalizer?.setEnabled(enabled);
  }

  @override
  Future<void> setGains(Map<int, double> changes) async {
    for (final entry in changes.entries) {
      if (entry.key < 0 || entry.key >= _bands.length) continue;
      await _bands[entry.key].setGain(EqMath.clamp(entry.value, _min, _max));
    }
  }

  @override
  Future<void> setPreamp(double db) async {}

  @override
  Future<void> release() async {}
}
