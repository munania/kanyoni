import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';

import 'eq_engine.dart';
import 'eq_math.dart';

/// One equalizer for the whole app.
///
/// It is "global" in the sense that a single setting applies to every song
/// and survives restarts (it is stored, and re-applied as soon as the player
/// gets an audio session). It does not touch other apps' audio.
class EqualizerController extends GetxController {
  static const String _kEnabled = 'eq2_enabled';
  static const String _kFreqs = 'eq2_freqs';
  static const String _kGains = 'eq2_gains';
  static const String _kPreamp = 'eq2_preamp';
  static const String _kPreset = 'eq2_preset';
  static const String _kCustom = 'eq2_custom';

  /// Slider drags are coalesced into one native call per this interval.
  static const Duration _applyDelay = Duration(milliseconds: 25);
  static const Duration _saveDelay = Duration(milliseconds: 600);
  static const double maxPreampDb = 12;

  final PlayerController _player = Get.find<PlayerController>();

  EqEngine? _engine;
  StreamSubscription<int?>? _sessionSub;
  int? _sessionId;
  int? _queuedSessionId;
  bool _starting = false;
  Timer? _applyTimer;
  Timer? _saveTimer;
  final Map<int, double> _pending = {};

  // --- state the UI observes -------------------------------------------------
  final RxBool enabled = false.obs;

  /// True once an engine is running (i.e. the player has an audio session).
  final RxBool isReady = false.obs;
  final RxBool canChangeBands = false.obs;
  final RxBool supportsPreamp = false.obs;
  final RxString engineName = ''.obs;

  final RxInt bandCount = 10.obs;
  final RxList<double> freqs = <double>[].obs;
  final RxList<double> gains = <double>[].obs;
  final RxDouble preamp = 0.0.obs;
  final RxDouble minDb = (-15.0).obs;
  final RxDouble maxDb = 15.0.obs;

  final RxString currentPreset = EqPresets.flat.obs;
  final RxMap<String, CustomPreset> customPresets =
      <String, CustomPreset>{}.obs;

  /// 'Custom' first, then built-ins, then the user's own presets.
  List<String> get presetNames => [
    EqPresets.custom,
    ...EqPresets.names,
    ...customPresets.keys,
  ];

  bool get isCustomPreset => customPresets.containsKey(currentPreset.value);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadSaved();
    if (!GetPlatform.isAndroid) return;

    // The stream replays its latest value, so it doesn't matter whether the
    // player already has a session by the time we subscribe.
    _sessionSub = _player.audioPlayer.androidAudioSessionIdStream.listen((id) {
      if (id != null) _startEngine(id);
    });
  }

  @override
  void onClose() {
    _applyTimer?.cancel();
    _saveTimer?.cancel();
    _sessionSub?.cancel();
    _save();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadSaved() async {
    try {
      final p = await prefs;
      enabled.value = p.getBool(_kEnabled) ?? false;
      preamp.value = (p.getDouble(_kPreamp) ?? 0.0)
          .clamp(-maxPreampDb, maxPreampDb)
          .toDouble();
      customPresets.assignAll(CustomPreset.decodeAll(p.getString(_kCustom)));

      final savedFreqs = _readDoubles(p.getStringList(_kFreqs));
      final savedGains = _readDoubles(p.getStringList(_kGains));
      if (savedFreqs.isNotEmpty && savedFreqs.length == savedGains.length) {
        freqs.assignAll(savedFreqs);
        gains.assignAll(savedGains);
      } else {
        freqs.assignAll(EqBands.forCount(10));
        gains.assignAll(List<double>.filled(10, 0.0));
      }
      bandCount.value = freqs.length;

      final preset = p.getString(_kPreset) ?? EqPresets.flat;
      currentPreset.value = presetNames.contains(preset)
          ? preset
          : EqPresets.custom;
    } catch (e) {
      if (kDebugMode) print('EqualizerController load failed: $e');
      freqs.assignAll(EqBands.forCount(10));
      gains.assignAll(List<double>.filled(10, 0.0));
    }
  }

  List<double> _readDoubles(List<String>? raw) => raw == null
      ? const []
      : raw.map(double.tryParse).whereType<double>().toList();

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
  }

  Future<void> _save() async {
    try {
      final p = await prefs;
      await p.setBool(_kEnabled, enabled.value);
      await p.setDouble(_kPreamp, preamp.value);
      await p.setString(_kPreset, currentPreset.value);
      await p.setStringList(_kFreqs, [for (final f in freqs) f.toString()]);
      await p.setStringList(_kGains, [for (final g in gains) g.toString()]);
      await p.setString(_kCustom, CustomPreset.encodeAll(customPresets));
    } catch (e) {
      if (kDebugMode) print('EqualizerController save failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Engine
  // ---------------------------------------------------------------------------

  Future<void> _startEngine(int sessionId) async {
    if (_sessionId == sessionId && isReady.value) return;
    if (_starting) {
      _queuedSessionId = sessionId;
      return;
    }
    _starting = true;

    try {
      await _engine?.release();
      _engine = null;

      EqEngine engine = DynamicsEqEngine();
      var ok = await engine.start(
        sessionId: sessionId,
        freqs: freqs.toList(),
        gains: gains.toList(),
        preampDb: preamp.value,
        enabled: enabled.value,
      );
      if (!ok) {
        engine = LegacyEqEngine(_player.androidEqualizer);
        ok = await engine.start(
          sessionId: sessionId,
          freqs: freqs.toList(),
          gains: gains.toList(),
          preampDb: preamp.value,
          enabled: enabled.value,
        );
      }

      if (!ok) {
        isReady.value = false;
        return;
      }

      _engine = engine;
      _sessionId = sessionId;
      engineName.value = engine.name;
      canChangeBands.value = engine.canChangeBands;
      supportsPreamp.value = engine.supportsPreamp;
      minDb.value = engine.minDb;
      maxDb.value = engine.maxDb;

      // The hardware engine dictates its own bands: keep the saved *shape*
      // by re-sampling it onto them.
      if (!sameFrequencies(engine.freqs, freqs.toList())) {
        final resampled = EqMath.resample(
          freqs.toList(),
          gains.toList(),
          engine.freqs,
        );
        freqs.assignAll(engine.freqs);
        gains.assignAll(resampled);
        bandCount.value = freqs.length;
      }

      // Make sure nothing is outside what this engine supports.
      var clamped = false;
      for (var i = 0; i < gains.length; i++) {
        final v = EqMath.clamp(gains[i], minDb.value, maxDb.value);
        if (v != gains[i]) {
          gains[i] = v;
          clamped = true;
        }
      }
      if (clamped || engine is! DynamicsEqEngine) {
        await engine.setGains({
          for (var i = 0; i < gains.length; i++) i: gains[i],
        });
      }

      isReady.value = true;
    } catch (e) {
      if (kDebugMode) print('EqualizerController engine start failed: $e');
      isReady.value = false;
    } finally {
      _starting = false;
      final queued = _queuedSessionId;
      _queuedSessionId = null;
      if (queued != null && queued != _sessionId) {
        unawaited(_startEngine(queued));
      }
    }
  }

  /// Re-initialises the running engine with the current layout (used when the
  /// band count changes).
  Future<void> _reconfigure() async {
    final engine = _engine;
    final session = _sessionId;
    if (engine == null || session == null) return;
    _pending.clear();
    await engine.start(
      sessionId: session,
      freqs: freqs.toList(),
      gains: gains.toList(),
      preampDb: preamp.value,
      enabled: enabled.value,
    );
  }

  void _scheduleApply() {
    _applyTimer ??= Timer(_applyDelay, _flush);
  }

  Future<void> _flush() async {
    _applyTimer = null;
    final engine = _engine;
    if (engine == null || _pending.isEmpty) return;
    final changes = Map<int, double>.from(_pending);
    _pending.clear();
    try {
      await engine.setGains(changes);
    } catch (e) {
      if (kDebugMode) print('EqualizerController apply failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    _scheduleSave();
    try {
      await _engine?.setEnabled(value);
    } catch (e) {
      if (kDebugMode) print('EqualizerController setEnabled failed: $e');
    }
  }

  /// Sets one band. Values are clamped to the engine's range and rounded to
  /// 0.1 dB.
  void setGain(int index, double db) {
    if (index < 0 || index >= gains.length) return;
    final value = EqMath.round(EqMath.clamp(db, minDb.value, maxDb.value));
    if (gains[index] == value) return;

    gains[index] = value;
    if (currentPreset.value != EqPresets.custom) {
      currentPreset.value = EqPresets.custom;
    }
    if (!enabled.value) setEnabled(true);

    _pending[index] = value;
    _scheduleApply();
    _scheduleSave();
  }

  /// +/- fine adjustment, 0.1 dB per step by default.
  void nudge(int index, double deltaDb) {
    if (index < 0 || index >= gains.length) return;
    setGain(index, gains[index] + deltaDb);
  }

  Future<void> setPreamp(double db) async {
    final value = EqMath.round(EqMath.clamp(db, -maxPreampDb, maxPreampDb));
    if (value == preamp.value) return;
    preamp.value = value;
    _scheduleSave();
    try {
      await _engine?.setPreamp(value);
    } catch (e) {
      if (kDebugMode) print('EqualizerController setPreamp failed: $e');
    }
  }

  /// Sets the preamp to exactly cancel the biggest boost, which keeps loud
  /// passages from clipping.
  Future<void> autoPreamp() =>
      setPreamp(EqMath.suggestedPreamp(gains.toList()));

  void _setAll(List<double> values, String presetName) {
    for (var i = 0; i < gains.length && i < values.length; i++) {
      final v = EqMath.round(EqMath.clamp(values[i], minDb.value, maxDb.value));
      if (gains[i] != v) {
        gains[i] = v;
        _pending[i] = v;
      }
    }
    currentPreset.value = presetName;
    if (!enabled.value) setEnabled(true);
    _scheduleApply();
    _scheduleSave();
  }

  /// Applies a built-in or saved preset, fitted to the current band layout.
  void applyPreset(String name) {
    if (name == EqPresets.custom) {
      currentPreset.value = EqPresets.custom;
      _scheduleSave();
      return;
    }
    final saved = customPresets[name];
    final values = saved != null
        ? saved.gainsFor(freqs.toList())
        : EqPresets.gainsFor(name, freqs.toList());
    if (values == null) return;
    _setAll(values, name);
  }

  Future<void> reset() async {
    applyPreset(EqPresets.flat);
    await setPreamp(0);
  }

  /// Changes the number of bands (10 / 15 / 31), keeping the current curve.
  Future<void> setBandCount(int count) async {
    if (!canChangeBands.value ||
        count == bandCount.value ||
        !EqBands.supportedCounts.contains(count)) {
      return;
    }
    final newFreqs = EqBands.forCount(count);
    final newGains = EqMath.resample(freqs.toList(), gains.toList(), newFreqs);
    freqs.assignAll(newFreqs);
    gains.assignAll(newGains);
    bandCount.value = count;
    _scheduleSave();
    await _reconfigure();
  }

  /// Saves the current curve under [name]. Returns an error message, or null
  /// on success.
  String? saveCustomPreset(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a name';
    if (trimmed == EqPresets.custom || EqPresets.isBuiltIn(trimmed)) {
      return '"$trimmed" is a built-in preset name';
    }
    customPresets[trimmed] = CustomPreset(
      name: trimmed,
      freqs: freqs.toList(),
      gains: gains.toList(),
    );
    currentPreset.value = trimmed;
    _scheduleSave();
    return null;
  }

  void deleteCustomPreset(String name) {
    if (customPresets.remove(name) == null) return;
    if (currentPreset.value == name) currentPreset.value = EqPresets.custom;
    _scheduleSave();
  }
}
