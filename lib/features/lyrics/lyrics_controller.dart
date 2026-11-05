import 'dart:async';

import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'lrc_parser.dart';
import 'lyrics_matcher.dart';
import 'lyrics_model.dart';
import 'lyrics_service.dart';
import 'lyrics_store.dart';

/// Loads lyrics for the playing song and keeps the highlighted line in sync.
///
/// The controller only does work while the lyrics view is on screen
/// ([activate] / [deactivate]), so it costs nothing (no network, no
/// subscriptions) when the user isn't looking at lyrics.
class LyricsController extends GetxController {
  final LyricsService _service = LyricsService();
  final LyricsStore _store = LyricsStore.instance;
  final PlayerController _player = Get.find<PlayerController>();

  final Rx<LyricsModel?> currentLyrics = Rx<LyricsModel?>(null);
  final RxList<LyricLine> parsedLyrics = <LyricLine>[].obs;
  final RxInt currentLineIndex = (-1).obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  /// True when the lines have real timestamps (can be highlighted in time).
  final RxBool isSynced = false.obs;
  final RxBool isInstrumental = false.obs;

  /// True when the lyrics were typed/pasted by the user.
  final RxBool isManual = false.obs;

  /// True when the last lookup failed because the service was unreachable.
  final RxBool isOffline = false.obs;

  /// Per-song timing correction in ms. Positive = lyrics appear earlier.
  final RxInt offsetMs = 0.obs;

  /// Lines are highlighted slightly ahead of the audio, because a line feels
  /// "late" if it only changes after it has already started being sung.
  static const int lookAheadMs = 650;
  static const int maxOffsetMs = 10000;

  StreamSubscription<Duration>? _positionSub;
  Worker? _indexWorker;
  Worker? _queueWorker;
  bool _active = false;
  int? _loadedSongId;
  int _token = 0;

  /// The raw text to show in the editor.
  String get editableText {
    final l = currentLyrics.value;
    if (l == null) return '';
    return l.hasSynced ? l.syncedLyrics : l.plainLyrics;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void activate() {
    if (_active) return;
    _active = true;

    // Reload when the *song* changes, not only when the index changes: the
    // queue can be replaced while the index stays the same (e.g. starting an
    // album at track 0 while track 0 of the library was playing).
    _indexWorker = ever(_player.currentSongIndex, (_) => _loadIfNeeded());
    _queueWorker = ever(_player.currentPlaylist, (_) => _loadIfNeeded());
    _positionSub = _player.audioPlayer.positionStream.listen(_syncLyrics);

    // Previously nothing was fetched for the song that was already playing
    // when the lyrics view opened, so the first song always showed
    // "No lyrics available".
    _loadIfNeeded();
  }

  void deactivate() {
    _active = false;
    _positionSub?.cancel();
    _positionSub = null;
    _indexWorker?.dispose();
    _indexWorker = null;
    _queueWorker?.dispose();
    _queueWorker = null;
    // Invalidate in-flight work, and make the next activate() reload.
    _token++;
    _loadedSongId = null;
  }

  @override
  void onClose() {
    deactivate();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  void _loadIfNeeded({bool force = false}) {
    if (!_active) return;
    final song = _player.activeSong;
    if (song == null) {
      _token++;
      _loadedSongId = null;
      _reset();
      isLoading.value = false;
      return;
    }
    if (!force && song.id == _loadedSongId) return;
    _loadedSongId = song.id;
    _load(song);
  }

  void _reset() {
    currentLyrics.value = null;
    parsedLyrics.clear();
    currentLineIndex.value = -1;
    isSynced.value = false;
    isInstrumental.value = false;
    isManual.value = false;
    isOffline.value = false;
    hasError.value = false;
    offsetMs.value = 0;
  }

  LyricsQuery _queryFor(SongModel song) {
    return LyricsQuery(
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      fileName: song.displayNameWOExt,
      durationSec: (song.duration ?? 0) / 1000,
    );
  }

  Future<void> _load(SongModel song, {bool ignoreCache = false}) async {
    final token = ++_token;
    isLoading.value = true;
    _reset();

    try {
      final savedOffset = await _store.getOffset(song.id);
      if (token != _token) return;
      offsetMs.value = savedOffset;

      // 1. Lyrics the user typed or pasted always win.
      final manual = await _store.getManual(song.id);
      if (token != _token) return;
      if (manual != null && manual.trim().isNotEmpty) {
        isManual.value = true;
        _apply(
          LyricsModel(
            id: song.id,
            trackName: song.title,
            artistName: song.artist ?? '',
            albumName: song.album ?? '',
            duration: (song.duration ?? 0) / 1000,
            instrumental: false,
            plainLyrics: manual,
            syncedLyrics: manual,
          ),
        );
        return;
      }

      // 2. Local cache (also remembers "not found" for a few days).
      if (!ignoreCache) {
        final cached = await _store.getCached(song.id);
        if (token != _token) return;
        if (cached != null) {
          if (cached.lyrics != null) {
            _apply(cached.lyrics!);
          } else {
            hasError.value = true;
          }
          return;
        }
      }

      // 3. Online.
      final result = await _service.lookup(_queryFor(song));
      if (token != _token) return;

      if (result.lyrics != null) {
        _apply(result.lyrics!);
        unawaited(_store.putCached(song.id, result.lyrics));
      } else {
        hasError.value = true;
        isOffline.value = result.networkError;
        // Only remember a miss when the service really answered.
        if (!result.networkError) {
          unawaited(_store.putCached(song.id, null));
        }
      }
    } catch (e) {
      if (token == _token) hasError.value = true;
    } finally {
      if (token == _token) isLoading.value = false;
    }
  }

  void _apply(LyricsModel lyrics) {
    currentLyrics.value = lyrics;

    final raw = lyrics.hasSynced ? lyrics.syncedLyrics : lyrics.plainLyrics;
    final parsed = LrcParser.parse(raw);

    parsedLyrics.assignAll(parsed.lines);
    isSynced.value = parsed.synced;
    isInstrumental.value = lyrics.instrumental && parsed.lines.isEmpty;
    hasError.value = parsed.lines.isEmpty && !isInstrumental.value;
    currentLineIndex.value = -1;
    _syncLyrics(_player.audioPlayer.position);
  }

  // ---------------------------------------------------------------------------
  // Syncing
  // ---------------------------------------------------------------------------

  void _syncLyrics(Duration position) {
    if (!isSynced.value || parsedLyrics.isEmpty) return;

    final syncPosition =
        position + Duration(milliseconds: lookAheadMs + offsetMs.value);
    final index = LrcParser.indexAt(parsedLyrics, syncPosition);

    if (currentLineIndex.value != index) {
      currentLineIndex.value = index;
    }
  }

  /// Nudges the sync of this song. Saved per song.
  Future<void> adjustOffset(int deltaMs) => setOffset(offsetMs.value + deltaMs);

  Future<void> setOffset(int ms) async {
    final song = _player.activeSong;
    offsetMs.value = ms.clamp(-maxOffsetMs, maxOffsetMs).toInt();
    _syncLyrics(_player.audioPlayer.position);
    if (song != null) {
      await _store.setOffset(song.id, offsetMs.value);
    }
  }

  /// Tap-to-seek: jump the song to where [index] is sung.
  Future<void> seekToLine(int index) async {
    if (!isSynced.value || index < 0 || index >= parsedLyrics.length) return;
    final target =
        parsedLyrics[index].time -
        Duration(milliseconds: lookAheadMs + offsetMs.value);
    await _player.audioPlayer.seek(target.isNegative ? Duration.zero : target);
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> saveManualLyrics(String lyrics) async {
    final song = _player.activeSong;
    if (song == null) return;

    if (lyrics.trim().isEmpty) {
      await _store.deleteManual(song.id);
    } else {
      await _store.setManual(song.id, lyrics);
    }
    _loadIfNeeded(force: true);
  }

  Future<void> deleteManualLyrics() async {
    final song = _player.activeSong;
    if (song == null) return;
    await _store.deleteManual(song.id);
    _loadIfNeeded(force: true);
  }

  /// Forget the cached result and search online again (e.g. wrong lyrics, or
  /// the earlier attempt happened while offline).
  Future<void> searchAgain() async {
    final song = _player.activeSong;
    if (song == null) return;
    await _store.deleteCached(song.id);
    _loadedSongId = song.id;
    await _load(song, ignoreCache: true);
  }
}
