// audio_handler.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import 'player_controller.dart';

class MediaPlayerHandler extends BaseAudioHandler {
  final PlayerController _playerController = Get.find<PlayerController>();
  List<SongModel> _lastKnownPlaylist = [];

  MediaPlayerHandler() {
    // Initialize queue
    _updateQueue();
    _updateMediaItem(_playerController.currentSongIndex.value);

    // Setup listeners
    // Use distinct to avoid unnecessary rebuilds
    _playerController.currentPlaylist.listen((newPlaylist) {
      if (!listEquals(newPlaylist, _lastKnownPlaylist)) {
        _lastKnownPlaylist = List.from(newPlaylist);
        _updateQueue();
        _updateMediaItem(_playerController.currentSongIndex.value);
      }
    });

    // React to index changes
    _playerController.currentSongIndex.listen(_updateMediaItem);

    // Update state continuously / Forward player state changes
    _playerController.positionDataStream.listen(_updatePlaybackState);
  }

  void _updateQueue() {
    queue.add(_playerController.currentPlaylist
        .map((song) => MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist,
              artUri: Uri.parse(song.uri ?? ''),
            ))
        .toList());
  }

  void _updateMediaItem(int index) {
    if (index >= 0 && index < _playerController.currentPlaylist.length) {
      final song = _playerController.currentPlaylist[index];
      mediaItem.add(MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
        artUri: Uri.parse(song.uri ?? ''),
      ));
    }
  }

  void _updatePlaybackState(PositionData positionData) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _playerController.isPlaying.value
            ? MediaControl.pause
            : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: _playerController.isPlaying.value,
      updatePosition: positionData.position,
      bufferedPosition: positionData.position,
      speed: 1.0,
    ));
  }

  @override
  Future<void> play() async {
    await _playerController.audioPlayer.play();
    _updatePlaybackState(PositionData(
      position: _playerController.audioPlayer.position,
      duration: _playerController.audioPlayer.duration ?? Duration.zero,
      isPlaying: true,
    ));
  }

  @override
  Future<void> pause() async {
    await _playerController.audioPlayer.pause();
    _updatePlaybackState(PositionData(
      position: _playerController.audioPlayer.position,
      duration: _playerController.audioPlayer.duration ?? Duration.zero,
      isPlaying: false,
    ));
  }

  @override
  Future<void> skipToNext() async {
    await _playerController.playNext();
    _updateMediaItem(_playerController.currentSongIndex.value);
  }

  @override
  Future<void> skipToPrevious() async {
    await _playerController.playPrevious();
    _updateMediaItem(_playerController.currentSongIndex.value);
  }

  @override
  Future<void> seek(Duration position) async {
    await _playerController.audioPlayer.seek(position);
    _updatePlaybackState(PositionData(
      position: position,
      duration: _playerController.audioPlayer.duration ?? Duration.zero,
      isPlaying: _playerController.isPlaying.value,
    ));
  }

  @override
  Future<void> stop() async {
    await _playerController.audioPlayer.stop();
    await super.stop();
  }
}
