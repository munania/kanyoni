import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
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

  // Equalizer Observables
  var equalizerEnabled = false.obs;
  var isEqualizerInitialized = false.obs;
  var equalizerBands = <int>[].obs;
  var equalizerCenterFreqs = <int>[].obs;
  var equalizerPresets = <String>[].obs;
  var currentPreset = ''.obs;
  var minBandLevel = 0.0.obs;
  var maxBandLevel = 0.0.obs;

  // Sleep Timer Observables
  var sleepTimerActive = false.obs;
  var sleepTimerDuration = 0.obs; // in seconds
  var sleepTimerRemaining = 0.obs; // in seconds
  Timer? _sleepTimer;

  Future<int?> get lastAppCloseTime async =>
      (await prefs).getInt(kLastAppCloseTimeKey);
  List<SongModel>? originalPlaylist;
  DateTime? _lastSaveTime;
  Timer? _scrollDebounceTimer;

  bool _isSongQueryInProgress = false;
  bool _songsLoadedSuccessfully = false;
  bool _shouldAttemptRestoreLastSong = false;

  @override
  void onInit() {
    super.onInit();
    _initializePreferences();
    _initializeAudioPlayer();

    // Initialize equalizer when audio session ID is available
    audioPlayer.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _initializeEqualizer(sessionId);
      }
    });
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
      // Restore last save time
      final prefsInstance = await prefs; // Get instance once
      final lastSaveTimeMillis = prefsInstance.getInt(kLastSaveTimeKey);
      if (lastSaveTimeMillis != null) {
        _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveTimeMillis);
        if (DateTime.now().difference(_lastSaveTime!) <= kMaxRestoreThreshold) {
          _shouldAttemptRestoreLastSong = true; // Set flag if within threshold
        } else {
          if (kDebugMode) {
            print(
                'Last save time exceeded threshold, skipping state restore for last song.');
          }
          _shouldAttemptRestoreLastSong = false;
        }
      } else {
        _shouldAttemptRestoreLastSong =
            false; // No last save time, so don't attempt restore
      }

      // Restore playback settings
      volume.value = prefsInstance.getDouble(kLastVolumeKey) ?? 1.0;
      audioPlayer.setVolume(volume.value);

      isShuffle.value = prefsInstance.getBool(kShuffleModeKey) ?? false;
      audioPlayer.setShuffleModeEnabled(isShuffle.value);

      final savedRepeatMode = prefsInstance.getInt(kRepeatModeKey) ?? 0;
      repeatMode.value = RepeatMode.values[savedRepeatMode];
      audioPlayer.setLoopMode(_getLoopMode(repeatMode.value));

      // Restore scroll position
      listScrollOffset.value =
          prefsInstance.getDouble(kLastListPositionKey) ?? 0.0;

      // Load favorite songs
      final favoriteSongIdsAsStrings =
          prefsInstance.getStringList(kFavoriteSongsKey);
      if (favoriteSongIdsAsStrings != null) {
        favoriteSongs.value =
            favoriteSongIdsAsStrings.map((id) => int.parse(id)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring state: $e');
      }
    }
  }

  Future<void> refreshSongs({SongSortType? sortType}) async {
    if (_isSongQueryInProgress) {
      if (kDebugMode) {
        print('RefreshSongs: Skipped as a song query is already in progress.');
      }
      return;
    }

    _isSongQueryInProgress = true;
    if (sortType != null) {
      currentSortType.value = sortType;
    }

    if (kDebugMode) {
      print(
          'RefreshSongs: Starting song query with sortType: ${currentSortType.value}');
    }

    try {
      // --- Core song fetching logic (similar to fetchAllSongs) ---
      var queriedSongs = await audioQuery.querySongs(
        sortType: currentSortType.value,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final newSongs = await applySongFilters(queriedSongs);

      if (kDebugMode) {
        print('RefreshSongs: Total songs loaded: ${newSongs.length}');
      }

      // Update the main songs list and currentPlaylist
      // Make sure to update songs.value which is observed by TracksView
      songs.value = newSongs;
      currentPlaylist.value =
          newSongs; // Or however currentPlaylist should be updated after a refresh

      _songsLoadedSuccessfully = true;
      if (kDebugMode) {
        print('Songs refreshed successfully.');
      }
    } catch (e) {
      _songsLoadedSuccessfully = false; // Explicitly set on error
      if (kDebugMode) {
        print('Error during refreshSongs: $e');
      }
      Get.snackbar("Error", "Failed to refresh songs: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSongQueryInProgress = false;
    }
  }

  Future<void> _restoreLastSong() async {
    if (kDebugMode) {
      print('[PlayerController._restoreLastSong] Called.');
    }
    if (songs.isEmpty) {
      // Safeguard
      if (kDebugMode) {
        print(
            "[PlayerController._restoreLastSong] Songs list is empty. Cannot restore.");
      }
      if (kDebugMode) {
        print(
            '[PlayerController._restoreLastSong] Songs list is empty. Cannot restore.');
      }
      return;
    }
    try {
      final prefsInstance = await prefs; // Get instance once
      final lastSongId = prefsInstance.getInt(kLastSongIdKey);
      final lastPosition = prefsInstance.getInt(kLastPositionKey);
      if (kDebugMode) {
        print(
            '[PlayerController._restoreLastSong] lastSongId: $lastSongId, lastPosition: $lastPosition');
      }

      if (lastSongId != null) {
        // songs.isNotEmpty is already checked
        final songIndex = songs.indexWhere((song) => song.id == lastSongId);
        if (kDebugMode) {
          print(
              '[PlayerController._restoreLastSong] Found songIndex: $songIndex for lastSongId: $lastSongId');
        }
        if (songIndex != -1) {
          // First set up the song without playing
          currentSongIndex.value = songIndex;
          await audioPlayer.setFilePath(songs[songIndex].data);

          // Then seek to the last position
          if (lastPosition != null) {
            await audioPlayer.seek(Duration(seconds: lastPosition));
            if (kDebugMode) {
              print(
                  '[PlayerController._restoreLastSong] Seeked to $lastPosition seconds for songId: $lastSongId.');
            }
          }

          // Ensure player is paused
          await audioPlayer.pause();
        } else {
          if (kDebugMode) {
            print(
                '[PlayerController._restoreLastSong] Song with ID $lastSongId not found in current songs list.');
          }
        }
      } else {
        if (kDebugMode) {
          print(
              '[PlayerController._restoreLastSong] No lastSongId found in SharedPreferences.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring last song: $e');
      }
      if (kDebugMode) {
        print(
            '[PlayerController._restoreLastSong] Error restoring last song: $e');
      }
    }
  }

  Future<void> _saveState() async {
    try {
      if (currentPlaylist.isEmpty ||
          currentSongIndex.value >= currentPlaylist.length) {
        return;
      }

      final currentSong = currentPlaylist[currentSongIndex.value];
      final position = audioPlayer.position.inSeconds;
      final prefsInstance = await prefs; // Get instance once

      await prefsInstance.setInt(kLastSongIdKey, currentSong.id);
      await prefsInstance.setInt(kLastPositionKey, position);
      await prefsInstance.setDouble(
          kLastListPositionKey, listScrollOffset.value);
      await prefsInstance.setDouble(kLastVolumeKey, volume.value);
      await prefsInstance.setBool(kShuffleModeKey, isShuffle.value);
      await prefsInstance.setInt(kRepeatModeKey, repeatMode.value.index);
      await prefsInstance.setInt(
          kLastSaveTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefsInstance.setInt(
          kLastAppCloseTimeKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        print('State saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving state: $e');
        print('Error saving app closure time: $e');
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

    final timeSinceClose = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastCloseTimeValue));

    return timeSinceClose < kScrollPositionRestoreThreshold;
  }

  void _debouncedSaveState() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(seconds: 1), _saveState);
  }

  void _initializeAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.playing) {
        _saveState();
      }
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });

    audioPlayer.setShuffleModeEnabled(false);
    audioPlayer.setLoopMode(LoopMode.off);
  }

  Future<void> fetchAllSongs() async {
    if (_isSongQueryInProgress || _songsLoadedSuccessfully) {
      if (kDebugMode) {
        print(
            'FetchAllSongs: Skipped as query in progress ($_isSongQueryInProgress) or songs already loaded ($_songsLoadedSuccessfully).');
      }
      return;
    }

    _isSongQueryInProgress = true;
    _songsLoadedSuccessfully = false; // Reset before attempting

    try {
      var queriedSongs = await audioQuery.querySongs(
        sortType: currentSortType.value,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      songs.value = await applySongFilters(queriedSongs);
      if (kDebugMode) {
        print('Total songs loaded: ${songs.length}');
      }
      if (kDebugMode) {
        print(
            '[PlayerController.fetchAllSongs] Fetched ${songs.length} songs.');
      }
      currentPlaylist.value = songs;
      if (kDebugMode) {
        print(
            '[PlayerController.fetchAllSongs] currentPlaylist set to length: ${currentPlaylist.length}');
      }
      _songsLoadedSuccessfully = true;

      if (_shouldAttemptRestoreLastSong) {
        await _restoreLastSong();
      }
    } catch (e) {
      _songsLoadedSuccessfully = false;
      if (kDebugMode) {
        print('Error loading songs: $e');
      }
      Get.snackbar("Error", "Failed to load songs: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isSongQueryInProgress = false;
    }
  }

  Future<void> playSong(dynamic input) async {
    if (kDebugMode) {
      print(
          '[PlayerController.playSong] Input: $input, currentPlaylist length: ${currentPlaylist.length}, currentIndex: ${currentSongIndex.value}');
    }
    try {
      int index;
      SongModel songToPlay;
      List<SongModel> playlist = List.from(currentPlaylist);

      if (input is SongModel) {
        // Handle direct song input
        songToPlay = input;
        index = playlist.indexWhere((song) =>
            song.title == songToPlay.title && song.artist == songToPlay.artist);

        // Add to playlist if not found
        if (index == -1) {
          playlist.add(songToPlay);
          index = playlist.length - 1;
          currentPlaylist.value = playlist; // Update playlist once
        }
      } else if (input is int) {
        // Handle index-based input
        index = input;
        if (index >= 0 && index < playlist.length) {
          songToPlay = playlist[index];
        } else {
          if (kDebugMode) {
            print(
                '[PlayerController.playSong] Error: Invalid song index $index for playlist length ${playlist.length}');
          }
          Get.snackbar('Error', 'Invalid song index',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
      } else {
        if (kDebugMode) {
          print(
              '[PlayerController.playSong] Error: Invalid input type for playSong - ${input.runtimeType}');
        }
        Get.snackbar('Error', 'Invalid input type for playSong',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Update current index
      currentSongIndex.value = index;

      // Play the song
      try {
        await audioPlayer.setFilePath(songToPlay.data);
        await audioPlayer.play();
        if (kDebugMode) {
          print(
              '[PlayerController.playSong] END - playing: ${songToPlay.title}, new playlist length: ${currentPlaylist.length}, new currentIndex: ${currentSongIndex.value}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PlayerController.playSong] Error playing song: $e');
        }
        Get.snackbar('Error', 'Error playing song: $e',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PlayerController.playSong] PlaySong general error: $e');
      }
      Get.snackbar('Error', 'PlaySong error: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> playNext() async {
    if (currentSongIndex.value < currentPlaylist.length - 1) {
      await playSong(currentSongIndex.value + 1);
    } else if (repeatMode.value == RepeatMode.all) {
      await playSong(0);
    }
  }

  Future<void> playPrevious() async {
    if (currentSongIndex.value > 0) {
      await playSong(currentSongIndex.value - 1);
    } else if (repeatMode.value == RepeatMode.all) {
      await playSong(currentPlaylist.length - 1);
    }
  }

  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      // Check if the player has a source loaded
      if ((audioPlayer.processingState == ProcessingState.idle ||
              audioPlayer.duration == null) &&
          currentPlaylist.isNotEmpty &&
          currentSongIndex.value >= 0 &&
          currentSongIndex.value < currentPlaylist.length) {
        // If not loaded but we have a valid song in the playlist, play it
        playSong(currentSongIndex.value);
      } else {
        // Otherwise just resume (or try to play if already loaded)
        audioPlayer.play();
      }
    }
  }

  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;

    if (currentPlaylist.isEmpty) {
      audioPlayer.setShuffleModeEnabled(isShuffle.value);
      originalPlaylist =
          null; // Ensure original is cleared if playlist is empty
      return; // Nothing to shuffle or restore
    }

    SongModel? currentSong;
    if (currentSongIndex.value >= 0 &&
        currentSongIndex.value < currentPlaylist.length) {
      currentSong = currentPlaylist[currentSongIndex.value];
    }

    if (isShuffle.value) {
      // Turning shuffle ON
      originalPlaylist ??= List<SongModel>.from(currentPlaylist);

      var tempList = List<SongModel>.from(currentPlaylist);

      if (currentSong != null) {
        tempList.removeWhere(
            (song) => song.id == currentSong!.id); // Remove current song by ID
      }

      tempList.shuffle();

      if (currentSong != null) {
        tempList.insert(0, currentSong); // Insert current song at the beginning
      }

      currentPlaylist.value = tempList;

      if (currentSong != null && currentPlaylist.isNotEmpty) {
        currentSongIndex.value = 0; // Current song is now at index 0
      } else if (currentPlaylist.isNotEmpty) {
        currentSongIndex.value =
            0; // No current song, but list is not empty, point to first
      } else {
        currentSongIndex.value = -1; // Playlist became empty
      }
      audioPlayer.setShuffleModeEnabled(true);
    } else {
      // Turning shuffle OFF
      if (originalPlaylist != null) {
        currentPlaylist.value = List<SongModel>.from(originalPlaylist!);
        originalPlaylist = null; // Clear the backup

        if (currentSong != null) {
          final newIndex =
              currentPlaylist.indexWhere((song) => song.id == currentSong!.id);
          if (newIndex != -1) {
            currentSongIndex.value = newIndex;
          } else {
            // Song was in shuffled list but not in original? Should not happen if logic is correct.
            // Default to 0 if playlist not empty.
            currentSongIndex.value = currentPlaylist.isNotEmpty ? 0 : -1;
          }
        } else {
          // No specific song was playing, or index was out of bounds.
          // Default to 0 if playlist not empty.
          currentSongIndex.value = currentPlaylist.isNotEmpty ? 0 : -1;
        }
      }
      // If originalPlaylist was null, it means shuffle was toggled off without being properly on,
      // or the playlist was empty. currentPlaylist remains as is, or was handled by empty check.
      audioPlayer.setShuffleModeEnabled(false);
    }
  }

  void toggleRepeatMode() {
    switch (repeatMode.value) {
      case RepeatMode.off:
        repeatMode.value = RepeatMode.one;
        audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        repeatMode.value = RepeatMode.all;
        audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        repeatMode.value = RepeatMode.off;
        audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  Future<void> toggleFavorite(int songId) async {
    if (favoriteSongs.contains(songId)) {
      favoriteSongs.remove(songId);
    } else {
      favoriteSongs.add(songId);
    }
    // Save favorite songs
    final prefsInstance = await prefs;
    final favoriteSongIdsAsStrings =
        favoriteSongs.map((id) => id.toString()).toList();
    await prefsInstance.setStringList(
        kFavoriteSongsKey, favoriteSongIdsAsStrings);
  }

  void setVolume(double value) {
    volume.value = value;
    audioPlayer.setVolume(value);
  }

  void setupAudioService() {
    ever(currentSongIndex, (index) {
      if (index >= 0 && index < currentPlaylist.length) {}
    });

    audioPlayer.playerStateStream.listen((state) {});
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
    cancelSleepTimer();
    _saveState();
    audioPlayer.dispose();
    super.onClose();
  }

  LoopMode _getLoopMode(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return LoopMode.off;
      case RepeatMode.one:
        return LoopMode.one;
      case RepeatMode.all:
        return LoopMode.all;
    }
  }

  Future<List<SongModel>> applySongFilters(List<SongModel> songs) async {
    final minLength = await getMinSongLength();
    final blacklistedFolders = await getBlacklistedFolders();

    if (minLength == 0 && blacklistedFolders.isEmpty) {
      return songs;
    }

    final minLengthMs = minLength * 1000;

    return songs.where((song) {
      final isLongEnough = song.duration! >= minLengthMs;
      final isInBlacklistedFolder =
          blacklistedFolders.any((folder) => song.data.startsWith(folder));
      return isLongEnough && !isInBlacklistedFolder;
    }).toList();
  }

  // Equalizer Methods
  Future<void> _initializeEqualizer(int sessionId) async {
    if (!Platform.isAndroid || androidEqualizer == null) return;

    try {
      await androidEqualizer!.setEnabled(true);

      final parameters = await androidEqualizer!.parameters;
      minBandLevel.value = parameters.minDecibels;
      maxBandLevel.value = parameters.maxDecibels;

      equalizerCenterFreqs.clear();
      equalizerBands.clear();

      for (var band in parameters.bands) {
        equalizerCenterFreqs.add(band.centerFrequency.toInt());
        equalizerBands.add(band.gain.toInt());

        band.gainStream.listen((gain) {
          if (equalizerBands.length > band.index) {
            equalizerBands[band.index] = gain.toInt();
            equalizerBands.refresh();
          }
        });
      }

      equalizerPresets.value = ['Custom', 'Flat', 'Bass Boost', 'Treble Boost'];
      currentPreset.value = 'Custom';
      equalizerEnabled.value = true;
      isEqualizerInitialized.value = true;

      if (kDebugMode) {
        print('Equalizer initialized with ${parameters.bands.length} bands');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing equalizer: $e');
      }
      isEqualizerInitialized.value = false;
    }
  }

  Future<void> toggleEqualizer(bool enabled) async {
    if (!isEqualizerInitialized.value || androidEqualizer == null) return;

    try {
      await androidEqualizer!.setEnabled(enabled);
      equalizerEnabled.value = enabled;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling equalizer: $e');
      }
    }
  }

  Future<void> setBandLevel(int bandId, double level) async {
    if (!isEqualizerInitialized.value || androidEqualizer == null) return;

    try {
      final parameters = await androidEqualizer!.parameters;
      if (bandId < parameters.bands.length) {
        await parameters.bands[bandId].setGain(level);
        currentPreset.value = 'Custom';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting band level: $e');
      }
    }
  }

  Future<void> setPreset(String presetName) async {
    if (!isEqualizerInitialized.value || androidEqualizer == null) return;

    try {
      final parameters = await androidEqualizer!.parameters;

      List<double> gains;
      switch (presetName) {
        case 'Flat':
          gains = List.filled(parameters.bands.length, 0.0);
          break;
        case 'Bass Boost':
          gains = List.generate(parameters.bands.length, (index) {
            if (index < 2) return maxBandLevel.value * 0.6;
            return 0.0;
          });
          break;
        case 'Treble Boost':
          gains = List.generate(parameters.bands.length, (index) {
            if (index > parameters.bands.length - 3) {
              return maxBandLevel.value * 0.6;
            }
            return 0.0;
          });
          break;
        case 'Custom':
        default:
          return;
      }

      for (int i = 0; i < parameters.bands.length && i < gains.length; i++) {
        await parameters.bands[i].setGain(gains[i]);
      }

      await Future.delayed(const Duration(milliseconds: 100));
      equalizerBands.refresh();
      currentPreset.value = presetName;

      if (kDebugMode) {
        print('Applied preset: $presetName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting preset: $e');
      }
    }
  }

  // Sleep Timer Methods
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

    if (kDebugMode) {
      print('Sleep timer started: $minutes minutes');
    }
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerActive.value = false;
    sleepTimerDuration.value = 0;
    sleepTimerRemaining.value = 0;

    if (kDebugMode) {
      print('Sleep timer cancelled');
    }
  }

  void _onSleepTimerExpired() {
    if (kDebugMode) {
      print('Sleep timer expired - pausing playback');
    }

    cancelSleepTimer();

    // Pause playback
    if (isPlaying.value) {
      togglePlayPause();
    }

    // Show notification
    Get.snackbar(
      'Sleep Timer',
      'Timer expired - playback paused',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
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

enum RepeatMode {
  off,
  one,
  all,
}
