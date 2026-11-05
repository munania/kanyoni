import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';
import '../playlist_logic.dart';

/// A snapshot of the library plus an index over it, so every playlist can be
/// matched against the same data without rebuilding it.
class _Library {
  final List<SongModel> songs;
  final LibraryIndex index;
  _Library(this.songs, this.index);
}

class PlaylistController extends BaseController {
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxMap<int, List<SongModel>> _playlistSongsCache =
      <int, List<SongModel>>{}.obs;

  /// playlistId -> { audioId -> [memberIds] }.
  ///
  /// MediaStore removes a song from a playlist by its *member row id*, and
  /// the same audio can be in a playlist more than once, so every member id
  /// is remembered (removing the song removes all of them).
  final Map<int, Map<int, List<int>>> _memberIds = {};

  final PlayerController _playerController = Get.find<PlayerController>();
  static const String _appPlaylistIdentifier = PlaylistNames.appTag;
  bool _isInitialized = false;
  Future<void>? _fetching;

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> fetchPlaylists({bool force = false}) async {
    // Startup and the home page both call this; share one load instead of
    // running two at once.
    if (_fetching != null) {
      await _fetching;
      if (!force) return;
    }
    if (_isInitialized && !force) return;

    final run = _fetch();
    _fetching = run;
    try {
      await run;
    } finally {
      _fetching = null;
    }
  }

  Future<void> _fetch() async {
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

      // Forget data of playlists that no longer exist.
      final ids = appPlaylists.map((p) => p.id).toSet();
      _playlistSongsCache.removeWhere((id, _) => !ids.contains(id));
      _memberIds.removeWhere((id, _) => !ids.contains(id));

      // Playlist entries can only be matched to songs once the library is
      // loaded. Startup used to load both at the same time, so entries were
      // matched against an empty library and cached with wrong ids.
      await _waitForLibrary();
      final library = _buildLibrary();
      if (library.songs.isEmpty) return; // try again on the next call

      await Future.wait([
        for (final playlist in appPlaylists)
          if (!_playlistSongsCache.containsKey(playlist.id))
            _loadPlaylistSongs(playlist.id, library: library),
      ]);

      _isInitialized = true;
    } catch (e) {
      _handleError('Loading playlists', e);
    }
  }

  Future<void> _waitForLibrary() async {
    try {
      await _playerController.libraryLoaded.timeout(
        const Duration(seconds: 20),
      );
    } on TimeoutException {
      // Carry on; the caller handles an empty library.
    }
  }

  _Library _buildLibrary() {
    final songs = _playerController.songs.toList();
    final index = LibraryIndex([
      for (final s in songs)
        SongIdentity(
          id: s.id,
          path: s.data,
          title: s.title,
          artist: s.artist ?? '',
          duration: s.duration,
        ),
    ]);
    return _Library(songs, index);
  }

  Future<void> _loadPlaylistSongs(int playlistId, {_Library? library}) async {
    try {
      final lib = library ?? _buildLibrary();
      if (lib.songs.isEmpty)
        return; // never cache results from an empty library

      final entries = await audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      // entry.id is the playlist *member* id, not the audio id, so entries
      // are matched to library songs by file path (exact), falling back to
      // title+artist+duration.
      final matches = lib.index.matchEntries([
        for (final e in entries)
          SongIdentity(
            id: e.id,
            path: e.data,
            title: e.title,
            artist: e.artist ?? '',
            duration: e.duration,
          ),
      ]);

      final members = <int, List<int>>{};
      final shown = <SongModel>[];
      final seen = <int>{};
      for (var i = 0; i < entries.length; i++) {
        final match = matches[i];
        if (match == null) {
          // Deleted, or hidden by the blacklist / minimum-length filter.
          continue;
        }
        final song = lib.songs[match];
        (members[song.id] ??= []).add(entries[i].id);
        if (seen.add(song.id)) shown.add(song);
      }

      _memberIds[playlistId] = members;
      _playlistSongsCache[playlistId] = shown;
    } catch (e) {
      _handleError('Loading songs for playlist $playlistId', e);
    }
  }

  /// Re-reads every playlist's songs, e.g. after tags were edited so the
  /// cached titles are no longer current.
  Future<void> reloadSongs() async {
    await _waitForLibrary();
    final library = _buildLibrary();
    await Future.wait([
      for (final playlist in playlists)
        _loadPlaylistSongs(playlist.id, library: library),
    ]);
    _playlistSongsCache.refresh();
  }

  PlaylistModel _createSanitizedPlaylist(PlaylistModel playlist) {
    return PlaylistModel({
      ...playlist.getMap,
      'playlist': playlist.playlist.replaceAll(' $_appPlaylistIdentifier', ''),
    });
  }

  Future<void> ensureSongsForPlaylistLoaded(int playlistId) async {
    final cached = _playlistSongsCache[playlistId];
    if (cached != null && cached.isNotEmpty) return;
    await _waitForLibrary();
    await _loadPlaylistSongs(playlistId);
  }

  // ---------------------------------------------------------------------------
  // Names
  // ---------------------------------------------------------------------------

  /// Display name of a playlist (reactive when read inside Obx).
  String? playlistName(int playlistId) {
    for (final p in playlists) {
      if (p.id == playlistId) return p.playlist;
    }
    return null;
  }

  /// Error text for a new/renamed name, or null when it is acceptable.
  String? validateName(String raw, {int? ignoreId}) {
    return PlaylistNames.validate(raw, [
      for (final p in playlists)
        if (p.id != ignoreId) p.playlist,
    ]);
  }

  // ---------------------------------------------------------------------------
  // Create / rename / delete
  // ---------------------------------------------------------------------------

  Future<PlaylistModel?> createPlaylist(String name) async {
    final problem = validateName(name);
    if (problem != null) {
      _showMessage('Error', problem);
      return null;
    }
    final clean = PlaylistNames.clean(name);

    try {
      final before = playlists.map((p) => p.id).toSet();
      final result = await audioQuery.createPlaylist(
        '$clean $_appPlaylistIdentifier',
      );
      if (result) {
        await fetchPlaylists(force: true);
        _showSuccess('Playlist created successfully');
        // Identify the new playlist by its id, not by name.
        return playlists.firstWhereOrNull((p) => !before.contains(p.id)) ??
            playlists.firstWhereOrNull((p) => p.playlist == clean);
      }
      _handleError('Creating playlist', 'Operation failed');
    } catch (e) {
      _handleError('Creating playlist', e);
    }
    return null;
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      // Optimistic update
      playlists.removeWhere((p) => p.id == playlistId);

      final result = await audioQuery.removePlaylist(playlistId);
      if (result) {
        _playlistSongsCache.remove(playlistId);
        _memberIds.remove(playlistId);
        // Give the OS a moment, otherwise the list can still contain it.
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchPlaylists(force: true);
        _showSuccess('Playlist deleted successfully');
      } else {
        // Restore it in the list and tell the user it failed.
        await fetchPlaylists(force: true);
        _handleError('Deleting playlist', 'Operation failed');
      }
    } catch (e) {
      await fetchPlaylists(force: true);
      _handleError('Deleting playlist', e);
    }
  }

  Future<void> clearAllPlaylists() async {
    try {
      final toDelete = List<PlaylistModel>.from(playlists);
      playlists.clear();

      var failed = 0;
      for (final playlist in toDelete) {
        final ok = await audioQuery.removePlaylist(playlist.id);
        if (ok) {
          _playlistSongsCache.remove(playlist.id);
          _memberIds.remove(playlist.id);
        } else {
          failed++;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await fetchPlaylists(force: true);

      if (failed == 0) {
        _showSuccess('All playlists cleared successfully');
      } else {
        _handleError('Clearing playlists', '$failed could not be deleted');
      }
    } catch (e) {
      await fetchPlaylists(force: true);
      _handleError('Clearing all playlists', e);
    }
  }

  Future<void> renamePlaylist(int playlistId, String newName) async {
    final problem = validateName(newName, ignoreId: playlistId);
    if (problem != null) {
      _showMessage('Error', problem);
      return;
    }
    try {
      final clean = PlaylistNames.clean(newName);
      final result = await audioQuery.renamePlaylist(
        playlistId,
        '$clean $_appPlaylistIdentifier',
      );

      if (result) {
        await fetchPlaylists(force: true);
        _showSuccess('Playlist renamed successfully');
      } else {
        _handleError('Renaming playlist', 'Operation failed');
      }
    } catch (e) {
      _handleError('Renaming playlist', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Songs in a playlist
  // ---------------------------------------------------------------------------

  /// Adds many songs in one go: one reload and one message, instead of a
  /// reload and a snackbar per song. Songs already in the playlist (matched by
  /// id) are skipped. Returns how many were actually added.
  Future<int> addSongsToPlaylist(
    int playlistId,
    List<SongModel> songs, {
    bool notify = true,
  }) async {
    if (songs.isEmpty) return 0;
    await ensureSongsForPlaylistLoaded(playlistId);

    final existing = {
      for (final s in _playlistSongsCache[playlistId] ?? <SongModel>[]) s.id,
    };
    final seen = <int>{};
    final toAdd = [
      for (final s in songs)
        if (!existing.contains(s.id) && seen.add(s.id)) s,
    ];
    final alreadyThere = songs.length - toAdd.length;

    var added = 0;
    for (final song in toAdd) {
      try {
        final result = await audioQuery.addToPlaylist(playlistId, song.id);
        if (_isOperationSuccessful(result)) added++;
      } catch (e) {
        if (kDebugMode) print('Error adding ${song.id} to $playlistId: $e');
      }
    }

    if (added > 0) {
      await _loadPlaylistSongs(playlistId);
      _playlistSongsCache.refresh();
    }

    if (notify) {
      if (added > 0) {
        final songWord = added == 1 ? 'song' : 'songs';
        _showSuccess(
          alreadyThere > 0
              ? 'Added $added $songWord ($alreadyThere already in the playlist)'
              : 'Added $added $songWord to the playlist',
        );
      } else if (toAdd.isEmpty) {
        _showSuccess('Already in the playlist');
      } else {
        _handleError('Adding to playlist', 'Operation failed');
      }
    }
    return added;
  }

  /// Adds one song. Returns true when the song is in the playlist afterwards
  /// (added now, or already there).
  Future<bool> addToPlaylist(int playlistId, int systemSongId) async {
    SongModel? song;
    for (final s in _playerController.songs) {
      if (s.id == systemSongId) {
        song = s;
        break;
      }
    }
    if (song == null) {
      _handleError('Adding to playlist', 'Song not found in system');
      return false;
    }

    await ensureSongsForPlaylistLoaded(playlistId);
    final alreadyThere = (_playlistSongsCache[playlistId] ?? []).any(
      (s) => s.id == systemSongId,
    );
    final added = await addSongsToPlaylist(playlistId, [song]);
    return alreadyThere || added > 0;
  }

  Future<void> removeFromPlaylist(int playlistId, int songId) async {
    try {
      final members = _memberIds[playlistId]?[songId];
      if (members == null || members.isEmpty) {
        _handleError('Removing song', 'Song not found in playlist');
        return;
      }

      var allRemoved = true;
      for (final memberId in List<int>.from(members)) {
        final result = await audioQuery.removeFromPlaylist(
          playlistId,
          memberId,
        );
        if (!_isOperationSuccessful(result)) allRemoved = false;
      }

      if (allRemoved) {
        final current = _playlistSongsCache[playlistId];
        if (current != null) {
          _playlistSongsCache[playlistId] = current
              .where((s) => s.id != songId)
              .toList();
        }
        _memberIds[playlistId]?.remove(songId);
        _playlistSongsCache.refresh();
        _showSuccess('Song removed from playlist');
      } else {
        // Re-read so the UI shows what is really in the playlist.
        await _loadPlaylistSongs(playlistId);
        _playlistSongsCache.refresh();
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

  List<SongModel> getPlaylistSongs(int playlistId) {
    return _playlistSongsCache[playlistId] ?? [];
  }

  Future<void> playPlaylist(int playlistId, {int startIndex = 0}) async {
    await ensureSongsForPlaylistLoaded(playlistId);
    final songs = getPlaylistSongs(playlistId);
    if (songs.isNotEmpty) {
      await _playerController.playQueue(songs, index: startIndex);
    }
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  void _handleError(String operation, dynamic error) {
    if (kDebugMode) print('Error $operation: $error');
    _showMessage('Error', 'Failed: $operation ($error)');
  }

  void _showSuccess(String message) => _showMessage('Success', message);

  void _showMessage(String title, String message) {
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
    } else if (kDebugMode) {
      print('$title: $message (No overlay found)');
    }
  }
}
