import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kanyoni/utils/helpers/path_filters.dart';
import 'package:kanyoni/utils/helpers/queue_ops.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

import 'base_controller.dart';

class PlayerController extends BaseController {
  // SharedPreferences keys
  static const String kLastSongIdKey = 'last_song_id';
  static const String kLastPositionKey = 'last_position_seconds';
  static const String kLastListPositionKey = 'last_list_position';
  static const String kLastVolumeKey = 'last_volume';
  static const String kShuffleModeKey = 'shuffle_mode';
  static const String kRepeatModeKey = 'repeat_mode';
  static const String kLastSaveTimeKey = 'last_save_time';
  static const String kFavoriteSongsKey = 'favoriteSongs';
  static const Duration kMaxRestoreThreshold = Duration(hours: 24);
  static const String kLastAppCloseTimeKey = 'last_app_close_time';
  static const Duration kScrollPositionRestoreThreshold = Duration(minutes: 30);

  /// How often the playback position is persisted while a song is playing.
  static const Duration kPositionSaveInterval = Duration(seconds: 15);

  /// The one and only audio engine in the app.
  ///
  /// [androidEqualizer] is only the *fallback* equalizer for devices without
  /// multi-band support; the app's equalizer lives in EqualizerController.
  late final AndroidEqualizer? androidEqualizer = GetPlatform.isAndroid
      ? AndroidEqualizer()
      : null;
  late final AudioPlayer audioPlayer = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [if (androidEqualizer != null) androidEqualizer!],
    ),
  );

  var currentSongIndex = 0.obs;
  var isPlaying = false.obs;
  var isShuffle = false.obs;
  var repeatMode = RepeatMode.off.obs;
  var favoriteSongs = <int>[].obs;
  var currentPlaylist = <SongModel>[].obs;
  var volume = 1.0.obs;
  var listScrollOffset = 0.0.obs; // For tracking list scroll position
  var currentSortType = SongSortType.DATE_ADDED.obs;

  // Computed getter for the currently active song
  SongModel? get activeSong {
    if (currentPlaylist.isEmpty ||
        currentSongIndex.value < 0 ||
        currentSongIndex.value >= currentPlaylist.length) {
      return null;
    }
    return currentPlaylist[currentSongIndex.value];
  }

  // Sleep Timer Observables
  var sleepTimerActive = false.obs;
  var sleepTimerDuration = 0.obs; // in seconds
  var sleepTimerRemaining = 0.obs; // in seconds
  Timer? _sleepTimer;

  Future<int?> get lastAppCloseTime async =>
      (await prefs).getInt(kLastAppCloseTimeKey);

  /// Un-shuffled copy of the queue, kept only while shuffle is on.
  List<SongModel>? originalPlaylist;
  DateTime? _lastSaveTime;
  Timer? _scrollDebounceTimer;
  Timer? _positionSaveTimer;

  final Completer<void> _libraryLoaded = Completer<void>();

  /// Completes once the song library has been read for the first time. Code
  /// that maps stored data (playlists, favourites) onto songs must wait for
  /// this, otherwise it sees an empty library.
  Future<void> get libraryLoaded => _libraryLoaded.future;

  bool _isSongQueryInProgress = false;
  bool _songsLoadedSuccessfully = false;
  bool _shouldAttemptRestoreLastSong = false;

  /// Incremented on every playSong so a slow, superseded load can't start
  /// playing after the user already picked another song.
  int _playToken = 0;

  @override
  void onInit() {
    super.onInit();
    _initializePreferences();
    _initializeAudioPlayer();
  }

  Future<void> _initializePreferences() async {
    try {
      await _restoreState();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing preferences: $e');
      }
    }
  }

  Future<void> _restoreState() async {
    try {
      final prefsInstance = await prefs;
      final lastSaveTimeMillis = prefsInstance.getInt(kLastSaveTimeKey);
      if (lastSaveTimeMillis != null) {
        _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveTimeMillis);
        _shouldAttemptRestoreLastSong =
            DateTime.now().difference(_lastSaveTime!) <= kMaxRestoreThreshold;
      } else {
        _shouldAttemptRestoreLastSong = false;
      }

      // Restore playback settings
      volume.value = prefsInstance.getDouble(kLastVolumeKey) ?? 1.0;
      audioPlayer.setVolume(volume.value);

      // Shuffle is applied to the queue when a queue is started (see
      // playQueue), so only the flag is restored here.
      isShuffle.value = prefsInstance.getBool(kShuffleModeKey) ?? false;

      final savedRepeatMode = (prefsInstance.getInt(kRepeatModeKey) ?? 0)
          .clamp(0, RepeatMode.values.length - 1)
          .toInt();
      repeatMode.value = RepeatMode.values[savedRepeatMode];
      _applyRepeatMode();

      listScrollOffset.value =
          prefsInstance.getDouble(kLastListPositionKey) ?? 0.0;

      final favoriteSongIdsAsStrings = prefsInstance.getStringList(
        kFavoriteSongsKey,
      );
      if (favoriteSongIdsAsStrings != null) {
        favoriteSongs.value = favoriteSongIdsAsStrings
            .map(int.tryParse)
            .whereType<int>()
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring state: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Library loading
  // ---------------------------------------------------------------------------

  Future<void> refreshSongs({SongSortType? sortType}) async {
    if (_isSongQueryInProgress) {
      return;
    }

    _isSongQueryInProgress = true;
    if (sortType != null) {
      currentSortType.value = sortType;
    }

    try {
      final queriedSongs = await audioQuery.querySongs(
        sortType: currentSortType.value,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final newSongs = await applySongFilters(queriedSongs);

      // The library list (observed by the Tracks tab).
      songs.value = newSongs;
      _syncQueueWithLibrary(newSongs);

      _songsLoadedSuccessfully = true;
      if (!_libraryLoaded.isCompleted) _libraryLoaded.complete();
    } catch (e) {
      _songsLoadedSuccessfully = false;
      if (kDebugMode) {
        print('Error during refreshSongs: $e');
      }
      Get.snackbar(
        "Error",
        "Failed to refresh songs: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSongQueryInProgress = false;
    }
  }

  Future<void> fetchAllSongs() async {
    if (_isSongQueryInProgress || _songsLoadedSuccessfully) {
      return;
    }

    _isSongQueryInProgress = true;
    _songsLoadedSuccessfully = false;

    try {
      final queriedSongs = await audioQuery.querySongs(
        sortType: currentSortType.value,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      songs.value = await applySongFilters(queriedSongs);
      _syncQueueWithLibrary(songs);
      _songsLoadedSuccessfully = true;
      if (!_libraryLoaded.isCompleted) _libraryLoaded.complete();

      if (_shouldAttemptRestoreLastSong) {
        await _restoreLastSong();
      }
    } catch (e) {
      _songsLoadedSuccessfully = false;
      if (kDebugMode) {
        print('Error loading songs: $e');
      }
      Get.snackbar(
        "Error",
        "Failed to load songs: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isSongQueryInProgress = false;
    }
  }

  /// Makes the library the queue only when nothing is loaded in the player.
  ///
  /// Previously every refresh replaced the queue, which silently changed what
  /// "next" meant (and desynchronised the current index) while an album,
  /// playlist or search result was playing.
  void _syncQueueWithLibrary(List<SongModel> library) {
    final nothingLoaded = audioPlayer.processingState == ProcessingState.idle;
    if (nothingLoaded || currentPlaylist.isEmpty) {
      currentPlaylist.value = List<SongModel>.from(library);
      if (currentSongIndex.value >= library.length) {
        currentSongIndex.value = 0;
      }
    }
  }

  Future<void> _restoreLastSong() async {
    if (songs.isEmpty) return;
    try {
      final prefsInstance = await prefs;
      final lastSongId = prefsInstance.getInt(kLastSongIdKey);
      final lastPosition = prefsInstance.getInt(kLastPositionKey);

      if (lastSongId == null) return;
      final songIndex = songs.indexWhere((song) => song.id == lastSongId);
      if (songIndex == -1) return;

      // Make sure the queue is the library the index refers to.
      if (currentPlaylist.length != songs.length ||
          currentPlaylist[songIndex].id != lastSongId) {
        currentPlaylist.value = List<SongModel>.from(songs);
      }

      currentSongIndex.value = songIndex;
      await audioPlayer.setFilePath(songs[songIndex].data);
      if (lastPosition != null) {
        await audioPlayer.seek(Duration(seconds: lastPosition));
      }
      await audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring last song: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // State persistence
  // ---------------------------------------------------------------------------

  Future<void> _saveState() async {
    try {
      final song = activeSong;
      if (song == null) return;

      final position = audioPlayer.position.inSeconds;
      final prefsInstance = await prefs;
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefsInstance.setInt(kLastSongIdKey, song.id);
      await prefsInstance.setInt(kLastPositionKey, position);
      await prefsInstance.setDouble(
        kLastListPositionKey,
        listScrollOffset.value,
      );
      await prefsInstance.setDouble(kLastVolumeKey, volume.value);
      await prefsInstance.setBool(kShuffleModeKey, isShuffle.value);
      await prefsInstance.setInt(kRepeatModeKey, repeatMode.value.index);
      await prefsInstance.setInt(kLastSaveTimeKey, now);
      await prefsInstance.setInt(kLastAppCloseTimeKey, now);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving state: $e');
      }
    }
  }

  Future<void> _savePlaybackModes() async {
    try {
      final prefsInstance = await prefs;
      await prefsInstance.setBool(kShuffleModeKey, isShuffle.value);
      await prefsInstance.setInt(kRepeatModeKey, repeatMode.value.index);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving playback modes: $e');
      }
    }
  }

  // Method to update scroll position from UI
  void updateListScrollPosition(double offset) {
    listScrollOffset.value = offset;
    _debouncedSaveState();
  }

  Future<bool> shouldRestoreScrollPosition() async {
    final lastCloseTimeValue = await lastAppCloseTime;
    if (lastCloseTimeValue == null) return false;

    final timeSinceClose = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastCloseTimeValue),
    );

    return timeSinceClose < kScrollPositionRestoreThreshold;
  }

  void _debouncedSaveState() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(seconds: 1), _saveState);
  }

  /// While playing, persist the position every [kPositionSaveInterval] so a
  /// killed app resumes near where it was (not where the song was started).
  void _startPositionSaving() {
    _positionSaveTimer ??= Timer.periodic(
      kPositionSaveInterval,
      (_) => _saveState(),
    );
  }

  void _stopPositionSaving() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  void _initializeAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.playing) {
        _startPositionSaving();
      } else {
        _stopPositionSaving();
      }
      // Save on both play and pause so the pause position is remembered.
      _saveState();
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    });

    // The queue is managed by this controller (one file at a time), so
    // just_audio's own shuffle is never used. Repeat-one is delegated to
    // just_audio; repeat-all is handled in [_onTrackCompleted].
    audioPlayer.setShuffleModeEnabled(false);
    audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> _onTrackCompleted() async {
    final hasNext = currentSongIndex.value < currentPlaylist.length - 1;
    if (hasNext || repeatMode.value == RepeatMode.all) {
      await playNext();
    } else {
      // End of the queue: stop cleanly instead of staying in a "playing but
      // completed" state.
      await audioPlayer.pause();
      await audioPlayer.seek(Duration.zero);
    }
  }

  /// Replaces the queue with [songs] and starts playing [index].
  ///
  /// This is the single entry point screens should use when the user taps a
  /// song in a list. It keeps shuffle consistent: with shuffle on, the chosen
  /// song plays first and the rest of the queue is shuffled.
  Future<void> playQueue(List<SongModel> songs, {int index = 0}) async {
    if (songs.isEmpty || index < 0 || index >= songs.length) return;

    final selected = songs[index];
    originalPlaylist = null;

    if (isShuffle.value) {
      originalPlaylist = List<SongModel>.from(songs);
      final rest = List<SongModel>.from(songs)
        ..removeAt(index)
        ..shuffle();
      currentPlaylist.value = [selected, ...rest];
      await playSong(0);
    } else {
      currentPlaylist.value = List<SongModel>.from(songs);
      await playSong(index);
    }
  }

  Future<void> playSong(dynamic input) async {
    try {
      int index;
      SongModel songToPlay;
      final List<SongModel> playlist = List.from(currentPlaylist);

      if (input is SongModel) {
        songToPlay = input;
        // Match on the MediaStore id. Matching on title+artist picked the
        // wrong track whenever two files shared both (live vs studio, dupes).
        index = playlist.indexWhere((song) => song.id == songToPlay.id);

        if (index == -1) {
          playlist.add(songToPlay);
          index = playlist.length - 1;
          currentPlaylist.value = playlist;
        }
      } else if (input is int) {
        index = input;
        if (index >= 0 && index < playlist.length) {
          songToPlay = playlist[index];
        } else {
          Get.snackbar(
            'Error',
            'Invalid song index',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      } else {
        Get.snackbar(
          'Error',
          'Invalid input type for playSong',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      currentSongIndex.value = index;
      final token = ++_playToken;

      try {
        await audioPlayer.setFilePath(songToPlay.data);
        // The user may have tapped another song while this one was loading.
        if (token != _playToken) return;

        // play() only completes when playback stops, so don't await it.
        unawaited(
          audioPlayer.play().catchError((Object e) {
            if (kDebugMode) {
              print('[PlayerController.playSong] play() error: $e');
            }
          }),
        );
      } catch (e) {
        if (token != _playToken) return;
        if (kDebugMode) {
          print('[PlayerController.playSong] Error playing song: $e');
        }
        Get.snackbar(
          'Error',
          'Error playing song: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PlayerController.playSong] PlaySong general error: $e');
      }
      Get.snackbar(
        'Error',
        'PlaySong error: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> playNext() async {
    if (currentSongIndex.value < currentPlaylist.length - 1) {
      await playSong(currentSongIndex.value + 1);
    } else if (repeatMode.value == RepeatMode.all &&
        currentPlaylist.isNotEmpty) {
      await playSong(0);
    }
  }

  Future<void> playPrevious() async {
    if (currentSongIndex.value > 0) {
      await playSong(currentSongIndex.value - 1);
    } else if (repeatMode.value == RepeatMode.all &&
        currentPlaylist.isNotEmpty) {
      await playSong(currentPlaylist.length - 1);
    }
  }

  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
      return;
    }

    final state = audioPlayer.processingState;
    final hasValidSong =
        currentPlaylist.isNotEmpty &&
        currentSongIndex.value >= 0 &&
        currentSongIndex.value < currentPlaylist.length;

    if (state == ProcessingState.completed) {
      // Finished the queue earlier: start the current song again.
      audioPlayer.seek(Duration.zero);
      unawaited(audioPlayer.play());
    } else if ((state == ProcessingState.idle ||
            audioPlayer.duration == null) &&
        hasValidSong) {
      // Nothing loaded yet: load and play the current song.
      playSong(currentSongIndex.value);
    } else {
      unawaited(audioPlayer.play());
    }
  }

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
    _savePlaybackModes();

    if (currentPlaylist.isEmpty) {
      originalPlaylist = null;
      return;
    }

    SongModel? currentSong;
    if (currentSongIndex.value >= 0 &&
        currentSongIndex.value < currentPlaylist.length) {
      currentSong = currentPlaylist[currentSongIndex.value];
    }

    if (isShuffle.value) {
      // Turning shuffle ON
      originalPlaylist ??= List<SongModel>.from(currentPlaylist);

      final tempList = List<SongModel>.from(currentPlaylist);
      if (currentSong != null) {
        tempList.removeWhere((song) => song.id == currentSong!.id);
      }
      tempList.shuffle();
      if (currentSong != null) {
        tempList.insert(0, currentSong);
      }

      currentPlaylist.value = tempList;
      currentSongIndex.value = currentPlaylist.isNotEmpty ? 0 : -1;
    } else {
      // Turning shuffle OFF
      if (originalPlaylist != null) {
        currentPlaylist.value = List<SongModel>.from(originalPlaylist!);
        originalPlaylist = null;

        if (currentSong != null) {
          final newIndex = currentPlaylist.indexWhere(
            (song) => song.id == currentSong!.id,
          );
          currentSongIndex.value = newIndex != -1
              ? newIndex
              : (currentPlaylist.isNotEmpty ? 0 : -1);
        } else {
          currentSongIndex.value = currentPlaylist.isNotEmpty ? 0 : -1;
        }
      }
    }
  }

  void toggleRepeatMode() {
    switch (repeatMode.value) {
      case RepeatMode.off:
        repeatMode.value = RepeatMode.one;
        break;
      case RepeatMode.one:
        repeatMode.value = RepeatMode.all;
        break;
      case RepeatMode.all:
        repeatMode.value = RepeatMode.off;
        break;
    }
    _applyRepeatMode();
    _savePlaybackModes();
  }

  /// Only repeat-one is delegated to just_audio. With one file loaded at a
  /// time, LoopMode.all would loop the *same* song forever instead of
  /// wrapping the queue, so repeat-all is implemented in [_onTrackCompleted].
  void _applyRepeatMode() {
    audioPlayer.setLoopMode(
      repeatMode.value == RepeatMode.one ? LoopMode.one : LoopMode.off,
    );
  }

  Future<void> toggleFavorite(int songId) async {
    if (favoriteSongs.contains(songId)) {
      favoriteSongs.remove(songId);
    } else {
      favoriteSongs.add(songId);
    }
    final prefsInstance = await prefs;
    await prefsInstance.setStringList(
      kFavoriteSongsKey,
      favoriteSongs.map((id) => id.toString()).toList(),
    );
  }

  void setVolume(double value) {
    volume.value = value;
    audioPlayer.setVolume(value);
  }

  Stream<PositionData> get positionDataStream =>
      CombineLatestStream.combine3<Duration, Duration?, bool, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.durationStream,
        audioPlayer.playingStream,
        (position, duration, isPlaying) => PositionData(
          position: position,
          duration: duration ?? Duration.zero,
          isPlaying: isPlaying,
        ),
      );

  @override
  void onClose() {
    _scrollDebounceTimer?.cancel();
    _stopPositionSaving();
    cancelSleepTimer();
    _saveState();
    audioPlayer.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Queue editing
  // ---------------------------------------------------------------------------

  /// True when nothing is loaded in the player, so there is no "current queue"
  /// worth appending to.
  bool get _hasNoActiveQueue =>
      currentPlaylist.isEmpty ||
      audioPlayer.processingState == ProcessingState.idle;

  void _applyQueue(QueueResult<SongModel> result) {
    currentPlaylist.value = result.items;
    currentSongIndex.value = result.currentIndex < 0 ? 0 : result.currentIndex;
  }

  /// Adds [newSongs] to the end of the queue. If nothing is playing yet they
  /// start a new queue instead.
  Future<void> addToQueue(List<SongModel> newSongs) async {
    if (newSongs.isEmpty) return;
    if (_hasNoActiveQueue) {
      await playQueue(newSongs);
      return;
    }
    final result = QueueOps.append<SongModel>(
      currentPlaylist.toList(),
      currentSongIndex.value,
      newSongs,
    );
    originalPlaylist?.addAll(newSongs);
    _applyQueue(result);
  }

  /// Inserts [newSongs] right after the song that is playing.
  Future<void> playNextInQueue(List<SongModel> newSongs) async {
    if (newSongs.isEmpty) return;
    if (_hasNoActiveQueue) {
      await playQueue(newSongs);
      return;
    }
    final result = QueueOps.insertAfterCurrent<SongModel>(
      currentPlaylist.toList(),
      currentSongIndex.value,
      newSongs,
    );
    originalPlaylist?.addAll(newSongs);
    _applyQueue(result);
  }

  /// Removes the queue entries at [indices]. If the playing song is among
  /// them, the song that takes its place is loaded (and keeps playing if
  /// music was playing).
  Future<void> removeFromQueue(Iterable<int> indices) async {
    final queue = currentPlaylist.toList();
    final valid = indices.where((i) => i >= 0 && i < queue.length).toSet();
    if (valid.isEmpty) return;

    final wasPlaying = audioPlayer.playing;
    final removedSongs = [for (final i in valid) queue[i]];
    final result = QueueOps.removeIndices<SongModel>(
      queue,
      currentSongIndex.value,
      valid,
    );

    final original = originalPlaylist;
    if (original != null) {
      for (final removed in removedSongs) {
        final at = original.indexWhere((s) => s.id == removed.id);
        if (at != -1) original.removeAt(at);
      }
    }

    _applyQueue(result);

    if (!result.currentRemoved) return;

    if (result.items.isEmpty) {
      _playToken++;
      await audioPlayer.stop();
      return;
    }
    if (wasPlaying) {
      await playSong(result.currentIndex);
    } else {
      await _loadWithoutPlaying(result.currentIndex);
    }
  }

  /// Removes everything except the song that is playing.
  Future<void> clearUpcomingQueue() async {
    final keep = currentSongIndex.value;
    await removeFromQueue([
      for (var i = 0; i < currentPlaylist.length; i++)
        if (i != keep) i,
    ]);
  }

  /// Drag-and-drop reordering. Indices are as reported by
  /// ReorderableListView.
  void moveInQueue(int oldIndex, int newIndex) {
    final result = QueueOps.move<SongModel>(
      currentPlaylist.toList(),
      currentSongIndex.value,
      oldIndex,
      newIndex,
    );
    _applyQueue(result);
  }

  /// Loads the song at [index] into the player without starting it.
  Future<void> _loadWithoutPlaying(int index) async {
    if (index < 0 || index >= currentPlaylist.length) return;
    final token = ++_playToken;
    try {
      await audioPlayer.setFilePath(currentPlaylist[index].data);
      if (token != _playToken) return;
      await audioPlayer.pause();
    } catch (e) {
      if (kDebugMode) print('Error loading song without playing: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Tag editing support
  // ---------------------------------------------------------------------------

  /// If [songId] is the song currently loaded in the player, stops the player
  /// (so the file isn't open while it is rewritten) and returns what is needed
  /// to resume. Returns null when the song isn't loaded.
  Future<EditResume?> releaseSongForEditing(int songId) async {
    final song = activeSong;
    if (song == null ||
        song.id != songId ||
        audioPlayer.processingState == ProcessingState.idle) {
      return null;
    }
    final resume = EditResume(
      path: song.data,
      position: audioPlayer.position,
      wasPlaying: audioPlayer.playing,
    );
    _playToken++; // cancel any load that is still in flight
    await audioPlayer.stop();
    return resume;
  }

  /// Puts playback back exactly where [releaseSongForEditing] left it.
  Future<void> restoreAfterEditing(EditResume? resume) async {
    if (resume == null) return;
    try {
      await audioPlayer.setFilePath(resume.path);
      await audioPlayer.seek(resume.position);
      if (resume.wasPlaying) unawaited(audioPlayer.play());
    } catch (e) {
      if (kDebugMode) print('Error restoring playback after edit: $e');
    }
  }

  /// Call after a song's tags changed: reloads the library and swaps the
  /// fresh metadata into the queue so titles update everywhere (including the
  /// notification).
  Future<void> onSongTagsEdited(int songId) async {
    await refreshSongs();

    SongModel? fresh;
    for (final s in songs) {
      if (s.id == songId) {
        fresh = s;
        break;
      }
    }
    if (fresh == null) return;

    var changed = false;
    for (var i = 0; i < currentPlaylist.length; i++) {
      if (currentPlaylist[i].id == songId) {
        currentPlaylist[i] = fresh;
        changed = true;
      }
    }
    final original = originalPlaylist;
    if (original != null) {
      for (var i = 0; i < original.length; i++) {
        if (original[i].id == songId) original[i] = fresh;
      }
    }
    if (changed) currentPlaylist.refresh();
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  Future<List<SongModel>> applySongFilters(List<SongModel> songs) async {
    final minLength = await getMinSongLength();
    final blacklistedFolders = await getBlacklistedFolders();

    if (minLength == 0 && blacklistedFolders.isEmpty) {
      return songs;
    }

    return songs.where((song) {
      if (isTooShort(song.duration, minLength)) return false;
      return !isInBlacklistedFolder(song.data, blacklistedFolders);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Sleep timer
  // ---------------------------------------------------------------------------

  void startSleepTimer(int minutes) {
    cancelSleepTimer(); // Cancel any existing timer

    sleepTimerDuration.value = minutes * 60;
    sleepTimerRemaining.value = minutes * 60;
    sleepTimerActive.value = true;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerRemaining.value > 0) {
        sleepTimerRemaining.value--;
      } else {
        _onSleepTimerExpired();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerActive.value = false;
    sleepTimerDuration.value = 0;
    sleepTimerRemaining.value = 0;
  }

  void _onSleepTimerExpired() {
    cancelSleepTimer();

    if (isPlaying.value) {
      togglePlayPause();
    }

    Get.snackbar(
      'Sleep Timer',
      'Timer expired - playback paused',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}

/// Playback state captured before a song file is rewritten.
class EditResume {
  final String path;
  final Duration position;
  final bool wasPlaying;

  const EditResume({
    required this.path,
    required this.position,
    required this.wasPlaying,
  });
}

class PositionData {
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  PositionData({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });
}

enum RepeatMode { off, one, all }
