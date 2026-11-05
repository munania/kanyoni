import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'player_controller.dart';

/// Bridges [PlayerController] to the system media session / notification.
class MediaPlayerHandler extends BaseAudioHandler {
  final PlayerController _playerController = Get.find<PlayerController>();
  List<int> _lastQueueIds = [];

  MediaPlayerHandler() {
    _initializeHandler();
  }

  void _initializeHandler() {
    _updateQueue();
    _updateMediaItem(_playerController.currentSongIndex.value);

    // Queue changes (compare by id: cheap, and avoids rebuilding the whole
    // MediaItem list when only an equal list was re-assigned).
    _playerController.currentPlaylist.listen((playlist) {
      final ids = playlist.map((s) => s.id).toList();
      if (!listEquals(ids, _lastQueueIds)) {
        _updateQueue();
      }
      // The queue can change under the same index (e.g. a new album starts
      // at index 0), so refresh the displayed item as well.
      _updateMediaItem(_playerController.currentSongIndex.value);
    });

    _playerController.currentSongIndex.listen((index) {
      _updateMediaItem(index);
      _updatePlaybackState();
    });

    // Push playback state only when something meaningful changes. The system
    // extrapolates the position from `updatePosition` + `speed`, so there is
    // no need to publish a new state on every position tick (~5 times/sec).
    final player = _playerController.audioPlayer;
    player.playerStateStream.listen((_) => _updatePlaybackState());
    player.playbackEventStream.listen(
      (_) => _updatePlaybackState(),
      onError: (Object e, StackTrace st) {
        if (kDebugMode) {
          print('Playback event error: $e');
        }
      },
    );
  }

  void _updateQueue() {
    final playlist = _playerController.currentPlaylist;
    _lastQueueIds = playlist.map((s) => s.id).toList();
    queue.add(playlist.map(_createMediaItem).toList());
  }

  MediaItem _createMediaItem(SongModel song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album,
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: Uri.parse(
        'content://media/external/audio/media/${song.id}/albumart',
      ),
      extras: <String, dynamic>{'uri': song.uri, 'data': song.data},
    );
  }

  void _updateMediaItem(int index) {
    final playlist = _playerController.currentPlaylist;
    if (index >= 0 && index < playlist.length) {
      mediaItem.add(_createMediaItem(playlist[index]));
    }
  }

  void _updatePlaybackState() {
    try {
      final player = _playerController.audioPlayer;
      final state = player.playerState;

      playbackState.add(
        PlaybackState(
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
          updatePosition: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
          queueIndex: _playerController.currentSongIndex.value,
        ),
      );
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
      // Same path as the in-app button, so it also handles "nothing loaded"
      // and "finished the queue" correctly.
      if (!_playerController.audioPlayer.playing) {
        _playerController.togglePlayPause();
      }
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
