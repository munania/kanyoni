import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class PlaylistController extends BaseController {
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxMap<int, List<SongModel>> _playlistSongsCache =
      <int, List<SongModel>>{}.obs;
  final PlayerController _playerController = Get.put(PlayerController());
  static const String _appPlaylistIdentifier = '[kanyoni]';

  @override
  void onInit() {
    super.onInit();
    _initializePlaylists();
  }

  Future<void> _initializePlaylists() async {
    try {
      final loadedPlaylists = await audioQuery.queryPlaylists(
        sortType: PlaylistSortType.PLAYLIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      final appPlaylists = loadedPlaylists
          .where((p) => p.playlist.endsWith(_appPlaylistIdentifier))
          .map(_createSanitizedPlaylist)
          .toList();

      playlists.value = appPlaylists;
      await _cachePlaylistSongs(appPlaylists);
    } catch (e) {
      _handleError('Loading playlists', e);
    }
  }

  PlaylistModel _createSanitizedPlaylist(PlaylistModel playlist) {
    return PlaylistModel({
      ...playlist.getMap,
      'playlist': playlist.playlist.replaceAll(' $_appPlaylistIdentifier', '')
    });
  }

  Future<void> _cachePlaylistSongs(List<PlaylistModel> playlists) async {
    _playlistSongsCache.clear();
    for (final playlist in playlists) {
      try {
        final songs = await audioQuery
            .queryAudiosFrom(
              AudiosFromType.PLAYLIST,
              playlist.id,
              orderType: OrderType.ASC_OR_SMALLER,
            )
            .then((value) => value.cast<SongModel>());

        _playlistSongsCache[playlist.id] = songs;
      } catch (e) {
        _handleError('Caching songs for playlist ${playlist.id}', e);
      }
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      final result =
          await audioQuery.createPlaylist("$name $_appPlaylistIdentifier");
      if (result) {
        await _initializePlaylists();
        _showSuccess('Playlist created successfully');
      }
    } catch (e) {
      _handleError('Creating playlist', e);
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      final result = await audioQuery.removePlaylist(playlistId);
      if (result) {
        playlists.removeWhere((p) => p.id == playlistId);
        _playlistSongsCache.remove(playlistId);
        _showSuccess('Playlist deleted successfully');
      }
    } catch (e) {
      _handleError('Deleting playlist', e);
    }
  }

  Future<void> renamePlaylist(int playlistId, String newName) async {
    try {
      final cleanName = newName.replaceAll(_appPlaylistIdentifier, '').trim();
      final result = await audioQuery.renamePlaylist(
          playlistId, "$cleanName $_appPlaylistIdentifier");

      if (result) {
        final index = playlists.indexWhere((p) => p.id == playlistId);
        if (index != -1) {
          playlists[index] = _createSanitizedPlaylist(playlists[index]);
          playlists.refresh();
        }
        _showSuccess('Playlist renamed successfully');
      }
    } catch (e) {
      _handleError('Renaming playlist', e);
    }
  }

  Future<bool> addToPlaylist(int playlistId, int systemSongId) async {
    try {
      final systemSong = _playerController.songs.firstWhere(
        (s) => s.id == systemSongId,
      );

      final existingIds =
          _playlistSongsCache[playlistId]?.map((s) => s.id) ?? [];
      final playlistSongId = _findSystemSongId(systemSong) ?? systemSongId;

      if (existingIds.contains(playlistSongId)) return true;

      final result = await audioQuery.addToPlaylist(playlistId, playlistSongId);

      if (result) {
        _playlistSongsCache[playlistId] = [
          ..._playlistSongsCache[playlistId] ?? [],
          systemSong
        ];
        _playlistSongsCache.refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> removeFromPlaylist(int playlistId, int songId) async {
    try {
      final result = await audioQuery.removeFromPlaylist(playlistId, songId);
      if (_isOperationSuccessful(result)) {
        _playlistSongsCache.update(
            playlistId, (songs) => songs.where((s) => s.id != songId).toList());
        _playlistSongsCache.refresh();
        _showSuccess('Song removed from playlist');
      }
    } catch (e) {
      _handleError('Removing song from playlist', e);
    }
  }

  bool _isOperationSuccessful(dynamic result) {
    return result.toString() == '1' ||
        result.toString().toLowerCase() == 'true';
  }

  int? _findSystemSongId(SongModel playlistSong) {
    try {
      return _playerController.songs
          .firstWhere(
            (systemSong) => _areSongsMatching(playlistSong, systemSong),
          )
          .id;
    } catch (e) {
      return null;
    }
  }

  bool _areSongsMatching(SongModel a, SongModel b) {
    return a.title == b.title &&
        a.artist == b.artist &&
        a.duration == b.duration &&
        a.data == b.data;
  }

  List<SongModel> getPlaylistSongs(int playlistId) {
    return _playlistSongsCache[playlistId] ?? [];
  }

  Future<void> playPlaylist(int playlistId, {int startIndex = 0}) async {
    final songs = getPlaylistSongs(playlistId);
    if (songs.isNotEmpty) {
      _playerController.currentPlaylist.value = songs;
      await _playerController.playSong(startIndex);
    }
  }

  void _handleError(String operation, dynamic error) {
    if (kDebugMode) print('Error $operation: $error');
    Get.snackbar('Error', 'Failed to $operation: ${error.toString()}',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String message) {
    Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
  }
}
