import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'player_controller.dart';

class MediaPlayerHandler extends BaseAudioHandler {
  final PlayerController _playerController = Get.find<PlayerController>();
  List<SongModel> _lastKnownPlaylist = [];

  MediaPlayerHandler() {
    _initializeHandler();
  }

  void _initializeHandler() {
    // Initial setup
    _updateQueue();
    _updateMediaItem(_playerController.currentSongIndex.value);

    // Listen to playlist changes
    _playerController.currentPlaylist.listen((playlist) {
      if (!listEquals(playlist, _lastKnownPlaylist)) {
        _lastKnownPlaylist = List.from(playlist);
        _updateQueue();
      }
    });

    // Listen to current song changes
    _playerController.currentSongIndex.listen((index) {
      _updateMediaItem(index);
    });

    // Listen to playback state changes
    _playerController.audioPlayer.playerStateStream.listen((playerState) {
      _updatePlaybackState();
    });

    // Listen to position changes
    _playerController.audioPlayer.positionStream.listen((_) {
      _updatePlaybackState();
    });
  }

  void _updateQueue() {
    queue.add(_playerController.currentPlaylist
        .map((song) => _createMediaItem(song))
        .toList());
  }

  MediaItem _createMediaItem(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album,
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri:
          Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
      extras: <String, dynamic>{
        'uri': song.uri,
        'data': song.data,
      },
    );
  }

  void _updateMediaItem(int index) {
    if (index >= 0 && index < _playerController.currentPlaylist.length) {
      final song = _playerController.currentPlaylist[index];
      mediaItem.add(_createMediaItem(song));
    }
  }

  void _updatePlaybackState() {
    try {
      final position = _playerController.audioPlayer.position;
      final state = _playerController.audioPlayer.playerState;

      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          state.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(state.processingState),
        playing: state.playing,
        updatePosition: position,
        bufferedPosition: position,
        speed: _playerController.audioPlayer.speed,
        queueIndex: _playerController.currentSongIndex.value,
      ));
    } catch (e) {
      if (kDebugMode) {
        print("Error updating playback state: $e");
      }
    }
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() async {
    try {
      await _playerController.audioPlayer.play();
      _updatePlaybackState();
    } catch (e) {
      if (kDebugMode) {
        print("Error playing: $e");
      }
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _playerController.audioPlayer.pause();
      _updatePlaybackState();
    } catch (e) {
      if (kDebugMode) {
        print("Error pausing: $e");
      }
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerController.audioPlayer.seek(position);
    _updatePlaybackState();
  }

  @override
  Future<void> skipToNext() async {
    try {
      if (_playerController.currentPlaylist.isNotEmpty) {
        await _playerController.playNext();
        _updatePlaybackState();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error skipping to next: $e");
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      if (_playerController.currentPlaylist.isNotEmpty) {
        await _playerController.playPrevious();
        _updatePlaybackState();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error skipping to previous: $e");
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _playerController.audioPlayer.stop();
      await super.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping: $e");
      }
    }
  }
}
