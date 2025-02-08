import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const Duration kMaxRestoreThreshold = Duration(hours: 24);
  static const String kLastAppCloseTimeKey = 'last_app_close_time';
  static const Duration kScrollPositionRestoreThreshold = Duration(minutes: 30);

  late SharedPreferences _prefs;
  var currentSongIndex = 0.obs;
  var isPlaying = false.obs;
  var isShuffle = false.obs;
  var repeatMode = RepeatMode.off.obs;
  var favoriteSongs = <int>[].obs;
  var currentPlaylist = <SongModel>[].obs;
  var volume = 1.0.obs;
  var listScrollOffset = 0.0.obs; // For tracking list scroll position
  int? get lastAppCloseTime => _prefs.getInt(kLastAppCloseTimeKey);
  List<SongModel>? originalPlaylist;
  DateTime? _lastSaveTime;
  Timer? _scrollDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    _initializePreferences();
    _initializeAudioPlayer();
    loadSongs();
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _restoreState();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing preferences: $e');
      }
    }
  }

  Future<void> _restoreState() async {
    try {
      // Restore last save time
      final lastSaveTimeMillis = _prefs.getInt(kLastSaveTimeKey);
      if (lastSaveTimeMillis != null) {
        _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveTimeMillis);

        // Check if we're within the restore threshold
        if (DateTime.now().difference(_lastSaveTime!) > kMaxRestoreThreshold) {
          if (kDebugMode) {
            print('Last save time exceeded threshold, skipping state restore');
          }
          return;
        }
      }

      // Restore playback settings
      volume.value = _prefs.getDouble(kLastVolumeKey) ?? 1.0;
      audioPlayer.setVolume(volume.value);

      isShuffle.value = _prefs.getBool(kShuffleModeKey) ?? false;
      audioPlayer.setShuffleModeEnabled(isShuffle.value);

      final savedRepeatMode = _prefs.getInt(kRepeatModeKey) ?? 0;
      repeatMode.value = RepeatMode.values[savedRepeatMode];
      audioPlayer.setLoopMode(_getLoopMode(repeatMode.value));

      // Restore scroll position
      listScrollOffset.value = _prefs.getDouble(kLastListPositionKey) ?? 0.0;

      // Restore last song and position after songs are loaded
      await loadSongs();
      await _restoreLastSong();
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring state: $e');
      }
    }
  }

  Future<void> _restoreLastSong() async {
    try {
      final lastSongId = _prefs.getInt(kLastSongIdKey);
      final lastPosition = _prefs.getInt(kLastPositionKey);

      if (lastSongId != null && songs.isNotEmpty) {
        final songIndex = songs.indexWhere((song) => song.id == lastSongId);
        if (songIndex != -1) {
          await playSong(songIndex);
          if (lastPosition != null) {
            await audioPlayer.seek(Duration(seconds: lastPosition));
            // Don't auto-play, just seek to position
            await audioPlayer.pause();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring last song: $e');
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

      await _prefs.setInt(kLastSongIdKey, currentSong.id);
      await _prefs.setInt(kLastPositionKey, position);
      await _prefs.setDouble(kLastListPositionKey, listScrollOffset.value);
      await _prefs.setDouble(kLastVolumeKey, volume.value);
      await _prefs.setBool(kShuffleModeKey, isShuffle.value);
      await _prefs.setInt(kRepeatModeKey, repeatMode.value.index);
      await _prefs.setInt(
          kLastSaveTimeKey, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setInt(
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

  bool shouldRestoreScrollPosition() {
    final lastCloseTime = lastAppCloseTime;
    if (lastCloseTime == null) return false;

    final timeSinceClose = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastCloseTime));

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

  Future<void> loadSongs() async {
    try {
      songs.value = await audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );
      if (kDebugMode) {
        print('Total songs loaded: ${songs.length}');
      }
      currentPlaylist.value = songs;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading songs: $e');
      }
      Get.snackbar("Error", "Failed to load songs: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> playSong(dynamic input) async {
    int index;
    SongModel songToPlay;

    if (input is SongModel) {
      // Handle direct song input
      songToPlay = input;
      index = currentPlaylist.indexWhere((song) =>
          song.title == songToPlay.title && song.artist == songToPlay.artist);

      // Add to playlist if not found
      if (index == -1) {
        currentPlaylist.add(songToPlay);
        index = currentPlaylist.length - 1;
      }
    } else if (input is int) {
      // Handle index-based input
      index = input;
      if (index >= 0 && index < currentPlaylist.length) {
        songToPlay = currentPlaylist[index];
      } else {
        Get.snackbar('Error', 'Invalid song index',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
    } else {
      Get.snackbar('Error', 'Invalid input for playSong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (index >= 0 && index < currentPlaylist.length) {
      try {
        final mainSong = songs.firstWhereOrNull((s) =>
            s.title == songToPlay.title && s.artist == songToPlay.artist);

        final songUri = (mainSong ?? songToPlay).uri;

        if (songUri != null) {
          currentSongIndex.value = index;
          await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songUri)));
          audioPlayer.play();
        } else {
          if (kDebugMode) {
            print('Song URI is null for song: ${songToPlay.title}');
          }
          Get.snackbar('Error', 'Cannot play song. File not found.',
              snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error playing song: $e');
        }
        Get.snackbar('Error', 'Failed to play song. File might be missing.',
            snackPosition: SnackPosition.BOTTOM);
      }
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
    audioPlayer.setShuffleModeEnabled(isShuffle.value);

    if (isShuffle.value) {
      originalPlaylist = List.from(currentPlaylist);
      currentPlaylist.shuffle();
    } else if (originalPlaylist != null) {
      currentPlaylist.value = originalPlaylist!;
      originalPlaylist = null;
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

  void toggleFavorite(int songId) {
    if (favoriteSongs.contains(songId)) {
      favoriteSongs.remove(songId);
    } else {
      favoriteSongs.add(songId);
    }
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
