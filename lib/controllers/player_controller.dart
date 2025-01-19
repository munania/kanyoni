import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

import 'base_controller.dart';

class PlayerController extends BaseController {
  var currentSongIndex = 0.obs;
  var isPlaying = false.obs;
  var isShuffle = false.obs;
  var repeatMode = RepeatMode.off.obs;
  var favoriteSongs = <int>[].obs;
  var currentPlaylist = <SongModel>[].obs;
  var volume = 1.0.obs;
  List<SongModel>? originalPlaylist;

  @override
  void onInit() {
    super.onInit();
    _initializeAudioPlayer();
    loadSongs();
  }

  void _initializeAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
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
      songToPlay = input;
      index = currentPlaylist.indexWhere((song) =>
          song.title == songToPlay.title && song.artist == songToPlay.artist);

      if (index == -1) {
        currentPlaylist.add(songToPlay);
        index = currentPlaylist.length - 1;
      }
    } else if (input is int) {
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
    audioPlayer.dispose();
    super.onClose();
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
