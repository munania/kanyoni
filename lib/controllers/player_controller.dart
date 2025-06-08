import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
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
  static const String kFavoriteSongsKey = 'favoriteSongs'; // Added key
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
    // fetchAllSongs(); // Removed call from here
  }

  Future<void> _initializePreferences() async {
    try {
      // _prefs = await SharedPreferences.getInstance(); // Removed
      await _restoreState(); // Ensure _restoreState is awaited
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

      // Last song restoration is now handled by fetchAllSongs
      // if (songs.isEmpty) { // Check if songs are not loaded
      // await fetchAllSongs(); // Call fetchAllSongs if songs are not loaded
      // }
      // await _restoreLastSong();
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring state: $e');
      }
    }
  }

  Future<void> refreshSongs() async {
    if (_isSongQueryInProgress) {
      if (kDebugMode) {
        print('RefreshSongs: Skipped as a song query is already in progress.');
      }
      return;
    }

    _isSongQueryInProgress = true;
    // _songsLoadedSuccessfully = false; // We will set this based on outcome

    if (kDebugMode) {
      print('RefreshSongs: Starting song query...');
    }

    try {
      // --- Core song fetching logic (similar to fetchAllSongs) ---
      final newSongs = await audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

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

      // Optional: If you want to re-apply the last song state after a refresh
      // if (_shouldAttemptRestoreLastSong) {
      //   await _restoreLastSong();
      // }
      // However, this might be unexpected during a manual refresh.
      // For now, let's keep it simple and not restore the last song automatically on manual refresh.
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
      songs.value = await audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
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
      audioPlayer.play();
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
