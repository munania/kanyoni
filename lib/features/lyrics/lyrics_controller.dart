import 'dart:async';
import 'dart:collection';

import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'lrc_parser.dart';
import 'lyrics_matcher.dart';
import 'lyrics_model.dart';
import 'lyrics_service.dart';
import 'lyrics_store.dart';

/// What is known about one song's lyrics. [lyrics] == null means "looked, and
/// there are none".
class _Loaded {
  final LyricsModel? lyrics;
  final bool manual;
  final int offsetMs;
  const _Loaded(this.lyrics, this.manual, this.offsetMs);

  _Loaded withOffset(int ms) => _Loaded(lyrics, manual, ms);
}

class _Resolved {
  final _Loaded loaded;

  /// The service could not be reached, so a miss must not be remembered.
  final bool offline;
  const _Resolved(this.loaded, {this.offline = false});
}

/// Loads lyrics for the playing song and keeps the highlighted line in sync.
///
/// The controller only does work while the lyrics view is on screen
/// ([activate] / [deactivate]), so it costs nothing (no network, no
/// subscriptions) when the user isn't looking at lyrics.
///
/// Speed: recently used lyrics are kept in memory (instant), the local reads
/// run concurrently, the online lookup runs its requests in parallel, and
/// while the view is open the *next* song's lyrics are fetched ahead of time.
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

  /// How many songs' lyrics stay in memory.
  static const int _memoryLimit = 24;

  final LinkedHashMap<int, _Loaded> _memory = LinkedHashMap<int, _Loaded>();
  final Set<int> _prefetching = {};

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

    // Fetch for the song that is already playing when the view opens.
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
  // Memory cache
  // ---------------------------------------------------------------------------

  void _remember(int songId, _Loaded value) {
    _memory.remove(songId); // re-insert so it counts as most recently used
    _memory[songId] = value;
    while (_memory.length > _memoryLimit) {
      _memory.remove(_memory.keys.first);
    }
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

  LyricsModel _manualModel(SongModel song, String text) {
    return LyricsModel(
      id: song.id,
      trackName: song.title,
      artistName: song.artist ?? '',
      albumName: song.album ?? '',
      duration: (song.duration ?? 0) / 1000,
      instrumental: false,
      plainLyrics: text,
      syncedLyrics: text,
    );
  }

  /// Works out the lyrics for [song]: the user's own lyrics, then the disk
  /// cache, then the internet. The three local reads run concurrently.
  Future<_Resolved> _resolve(
    SongModel song, {
    required bool ignoreCache,
  }) async {
    final local = await Future.wait<dynamic>([
      _store.getOffset(song.id),
      _store.getManual(song.id),
      ignoreCache
          ? Future<CachedLyrics?>.value(null)
          : _store.getCached(song.id),
    ]);
    final offset = local[0] as int;
    final manual = local[1] as String?;
    final cached = local[2] as CachedLyrics?;

    if (manual != null && manual.trim().isNotEmpty) {
      return _Resolved(_Loaded(_manualModel(song, manual), true, offset));
    }
    if (cached != null) {
      return _Resolved(_Loaded(cached.lyrics, false, offset));
    }

    final result = await _service.lookup(_queryFor(song));
    if (result.lyrics != null) {
      unawaited(_store.putCached(song.id, result.lyrics));
      return _Resolved(_Loaded(result.lyrics, false, offset));
    }
    if (result.networkError) {
      return _Resolved(_Loaded(null, false, offset), offline: true);
    }
    // The service answered and has nothing: remember that for a few days.
    unawaited(_store.putCached(song.id, null));
    return _Resolved(_Loaded(null, false, offset));
  }

  Future<void> _load(SongModel song, {bool ignoreCache = false}) async {
    final token = ++_token;

    // Instant path: seen recently, so no spinner and no waiting at all.
    final remembered = ignoreCache ? null : _memory[song.id];
    if (remembered != null) {
      _reset();
      isLoading.value = false;
      _show(remembered, offline: false);
      _prefetchNext();
      return;
    }

    isLoading.value = true;
    _reset();

    try {
      final resolved = await _resolve(song, ignoreCache: ignoreCache);
      if (token != _token) return;

      _show(resolved.loaded, offline: resolved.offline);
      if (!resolved.offline) _remember(song.id, resolved.loaded);
      _prefetchNext();
    } catch (e) {
      if (token == _token) hasError.value = true;
    } finally {
      if (token == _token) isLoading.value = false;
    }
  }

  void _show(_Loaded loaded, {required bool offline}) {
    offsetMs.value = loaded.offsetMs;
    isManual.value = loaded.manual;
    final lyrics = loaded.lyrics;
    if (lyrics != null) {
      _apply(lyrics);
    } else {
      hasError.value = true;
      isOffline.value = offline;
    }
  }

  /// While the user is reading lyrics, get the next song's ready so it
  /// appears immediately when the song changes. Only runs while the lyrics
  /// view is open.
  Future<void> _prefetchNext() async {
    if (!_active) return;
    final nextIndex = _player.currentSongIndex.value + 1;
    if (nextIndex < 0 || nextIndex >= _player.currentPlaylist.length) return;

    final next = _player.currentPlaylist[nextIndex];
    if (_memory.containsKey(next.id) || !_prefetching.add(next.id)) return;
    try {
      final resolved = await _resolve(next, ignoreCache: false);
      if (!resolved.offline) _remember(next.id, resolved.loaded);
    } catch (_) {
      // Prefetching is best effort.
    } finally {
      _prefetching.remove(next.id);
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
      final remembered = _memory[song.id];
      if (remembered != null) {
        _memory[song.id] = remembered.withOffset(offsetMs.value);
      }
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

    _memory.remove(song.id);
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
    _memory.remove(song.id);
    await _store.deleteManual(song.id);
    _loadIfNeeded(force: true);
  }

  /// Drops what is remembered in memory for [songId] (e.g. after its tags
  /// were edited, since lyrics are looked up by title and artist).
  void forget(int songId) => _memory.remove(songId);

  /// Forget the cached result and search online again (e.g. wrong lyrics, or
  /// the earlier attempt happened while offline).
  Future<void> searchAgain() async {
    final song = _player.activeSong;
    if (song == null) return;
    _memory.remove(song.id);
    await _store.deleteCached(song.id);
    _loadedSongId = song.id;
    await _load(song, ignoreCache: true);
  }
}
