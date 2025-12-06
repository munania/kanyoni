import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class PlaylistController extends BaseController {
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxMap<int, List<SongModel>> _playlistSongsCache =
      <int, List<SongModel>>{}.obs;
  final RxMap<int, Map<int, int>> _playlistMemberIdMap =
      <int, Map<int, int>>{}.obs; // PlaylistID -> { AudioID -> MemberID }
  final PlayerController _playerController = Get.put(PlayerController());
  static const String _appPlaylistIdentifier = '[kanyoni]';
  bool _isInitialized = false;

  Future<void> fetchPlaylists({bool force = false}) async {
    if (_isInitialized && !force) return;

    try {
      final loadedPlaylists = await audioQuery.queryPlaylists(
        sortType: PlaylistSortType.PLAYLIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // Process playlists in a single operation
      final appPlaylists = loadedPlaylists
          .where((p) => p.playlist.endsWith(_appPlaylistIdentifier))
          .map(_createSanitizedPlaylist)
          .toList();

      // Set playlists once
      playlists.value = appPlaylists;

      // Load songs sequentially
      for (var playlist in appPlaylists) {
        if (!_playlistSongsCache.containsKey(playlist.id)) {
          await _loadPlaylistSongs(playlist.id);
        }
      }

      _isInitialized = true;
    } catch (e) {
      _handleError('Loading playlists', e);
    }
  }

  Future<void> _loadPlaylistSongs(int playlistId) async {
    try {
      final songs = await audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      // Initialize member ID map for this playlist
      _playlistMemberIdMap[playlistId] = {};

      // Map playlist songs to system songs to ensure we have full metadata and correct IDs
      final mappedSongs = songs.map((playlistSong) {
        // playlistSong.id is the MEMBER ID (playlist entry ID)
        final memberId = playlistSong.id;

        // Try to find the song in the system songs list by matching metadata
        final systemSong = _playerController.songs.firstWhere(
          (s) => _areSongsMatching(s, playlistSong),
          orElse: () => playlistSong,
        );

        // Store mapping: AudioID -> MemberID
        _playlistMemberIdMap[playlistId]![systemSong.id] = memberId;
        if (kDebugMode) {
          print('Mapped: AudioID ${systemSong.id} -> MemberID $memberId');
        }

        return systemSong;
      }).toList();

      _playlistSongsCache[playlistId] = mappedSongs;
    } catch (e) {
      _handleError('Loading songs for playlist $playlistId', e);
    }
  }

  PlaylistModel _createSanitizedPlaylist(PlaylistModel playlist) {
    return PlaylistModel({
      ...playlist.getMap,
      'playlist': playlist.playlist.replaceAll(' $_appPlaylistIdentifier', '')
    });
  }

  Future<void> ensureSongsForPlaylistLoaded(int playlistId) async {
    if (_playlistSongsCache[playlistId] != null &&
        _playlistSongsCache[playlistId]!.isNotEmpty) {
      return; // Already loaded or cached
    }
    await _loadPlaylistSongs(playlistId);
  }

  Future<PlaylistModel?> createPlaylist(String name) async {
    try {
      final result =
          await audioQuery.createPlaylist("$name $_appPlaylistIdentifier");
      if (result) {
        await fetchPlaylists(force: true);
        _showSuccess('Playlist created successfully');
        return playlists.firstWhereOrNull((p) => p.playlist == name);
      }
    } catch (e) {
      _handleError('Creating playlist', e);
    }
    return null;
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      // Optimistic update
      playlists.removeWhere((p) => p.id == playlistId);
      _playlistMemberIdMap.remove(playlistId);

      final result = await audioQuery.removePlaylist(playlistId);
      if (result) {
        // Wait for OS to update
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchPlaylists(force: true);
        _showSuccess('Playlist deleted successfully');
      } else {
        // Revert if failed (fetch will restore it)
        await fetchPlaylists(force: true);
        _showSuccess('Failed to delete playlist');
      }
    } catch (e) {
      _handleError('Deleting playlist', e);
    }
  }

  Future<void> clearAllPlaylists() async {
    try {
      // Optimistic clear
      final playlistsToDelete = List<PlaylistModel>.from(playlists);
      playlists.clear();
      _playlistSongsCache.clear();
      _playlistMemberIdMap.clear();

      for (var playlist in playlistsToDelete) {
        await audioQuery.removePlaylist(playlist.id);
      }

      // Wait for OS to update
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchPlaylists(force: true);
      _showSuccess('All playlists cleared successfully');
    } catch (e) {
      // Revert if failed (fetch will restore it)
      await fetchPlaylists(force: true);
      _handleError('Clearing all playlists', e);
    }
  }

  Future<void> renamePlaylist(int playlistId, String newName) async {
    try {
      if (kDebugMode) print('Renaming playlist $playlistId to $newName');

      final cleanName = newName.replaceAll(_appPlaylistIdentifier, '').trim();
      final finalName = "$cleanName $_appPlaylistIdentifier";

      if (kDebugMode) print('Final name: $finalName');

      final result = await audioQuery.renamePlaylist(playlistId, finalName);

      if (result) {
        if (kDebugMode) print('Rename successful');
        // Refresh all playlists to ensure sync
        await fetchPlaylists(force: true);
        _showSuccess('Playlist renamed successfully');
      } else {
        if (kDebugMode) print('Rename failed');
        _handleError('Renaming playlist', 'Operation failed');
      }
    } catch (e) {
      _handleError('Renaming playlist', e);
    }
  }

  Future<bool> addToPlaylist(int playlistId, int systemSongId) async {
    await ensureSongsForPlaylistLoaded(
        playlistId); // Ensure songs are loaded/cached first
    try {
      final systemSong = _playerController.songs.firstWhereOrNull(
        (s) => s.id == systemSongId,
      );

      if (systemSong == null) {
        _handleError('Adding to playlist', 'Song not found in system');
        return false;
      }

      final existingSongModels = _playlistSongsCache[playlistId] ?? [];

      // Check if song is already in playlist (by ID or metadata match)
      final isAlreadyInPlaylist = existingSongModels
          .any((s) => s.id == systemSongId || _areSongsMatching(s, systemSong));

      if (isAlreadyInPlaylist) {
        if (kDebugMode) print('Song already in playlist.');
        return true; // Already in playlist
      }

      // We use the systemSongId to add.
      // Note: If the file was rescanned, the ID might have changed, but systemSongId
      // comes from the current system list, so it should be valid for the MediaStore.
      final result = await audioQuery.addToPlaylist(playlistId, systemSongId);

      if (_isOperationSuccessful(result)) {
        // Reload playlist to get the new member ID for the added song
        await _loadPlaylistSongs(playlistId);
        _playlistSongsCache.refresh();
        _showSuccess('Added to playlist');
        return true;
      } else {
        _handleError('Adding to playlist', 'Operation failed');
        return false;
      }
    } catch (e) {
      _handleError('Adding to playlist $playlistId', e);
      return false;
    }
  }

  Future<void> removeFromPlaylist(int playlistId, int songId) async {
    try {
      if (kDebugMode) print('Removing song $songId from playlist $playlistId');

      // Look up the Member ID using the Audio ID (songId)
      int? memberId;
      if (_playlistMemberIdMap.containsKey(playlistId)) {
        memberId = _playlistMemberIdMap[playlistId]?[songId];
      }

      if (memberId == null) {
        if (kDebugMode) print('Member ID not found for audio ID $songId');
        _handleError('Removing song', 'Song not found in playlist');
        return;
      }

      if (kDebugMode) print('Using Member ID: $memberId for removal');

      // Perform removal using Member ID
      final result = await audioQuery.removeFromPlaylist(playlistId, memberId);

      if (_isOperationSuccessful(result)) {
        if (kDebugMode) print('Removal successful');
        // Update local cache
        final currentSongs = _playlistSongsCache[playlistId];
        if (currentSongs != null) {
          final updatedSongs =
              currentSongs.where((s) => s.id != songId).toList();
          _playlistSongsCache[playlistId] = updatedSongs;

          // Remove from member ID map
          _playlistMemberIdMap[playlistId]?.remove(songId);

          _playlistSongsCache.refresh();
        }
        _showSuccess('Song removed from playlist');
      } else {
        if (kDebugMode) print('Failed to remove song from playlist');
        // Force reload to ensure UI is in sync with reality
        await _loadPlaylistSongs(playlistId);
        _handleError('Removing song', 'Failed to remove from playlist');
      }
    } catch (e) {
      _handleError('Removing song from playlist', e);
    }
  }

  bool _isOperationSuccessful(dynamic result) {
    return result.toString() == '1' ||
        result.toString().toLowerCase() == 'true';
  }

  bool _areSongsMatching(SongModel a, SongModel b) {
    return a.title.trim() == b.title.trim() &&
        (a.artist ?? '<unknown>') == (b.artist ?? '<unknown>') &&
        a.duration == b.duration;
  }

  List<SongModel> getPlaylistSongs(int playlistId) {
    return _playlistSongsCache[playlistId] ?? [];
  }

  Future<void> playPlaylist(int playlistId, {int startIndex = 0}) async {
    await ensureSongsForPlaylistLoaded(playlistId); // Ensure songs are loaded
    final songs = getPlaylistSongs(playlistId);
    if (songs.isNotEmpty) {
      _playerController.currentPlaylist.value = songs;
      await _playerController.playSong(startIndex);
    }
  }

  void _handleError(String operation, dynamic error) {
    if (kDebugMode) print('Error $operation: $error');
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar('Error', 'Failed to $operation: ${error.toString()}',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showSuccess(String message) {
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar('Success', message, snackPosition: SnackPosition.BOTTOM);
    } else {
      if (kDebugMode) print('Success: $message (No overlay found)');
    }
  }
}
