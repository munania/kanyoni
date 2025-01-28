import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';

class PlaylistController extends BaseController {
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;
  final RxMap<int, List<SongModel>> playlistSongs =
      <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.put(PlayerController());
  RxInt songCount = 0.obs;

  static const String appPlaylistIdentifier = '[kanyoni]';

  @override
  void onInit() {
    super.onInit();
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    try {
      final List<PlaylistModel> loadedPlaylists =
          await audioQuery.queryPlaylists(
        sortType: PlaylistSortType.PLAYLIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      // Filter playlists created by your app
      final appPlaylists = loadedPlaylists.where((playlist) {
        return playlist.playlist.endsWith('[kanyoni]');
      }).map((playlist) {
        // Create a new playlist model with the app identifier removed
        return PlaylistModel({
          ...playlist.getMap,
          'playlist': playlist.playlist.replaceAll(' [kanyoni]', '')
        });
      }).toList();

      playlists.value = appPlaylists;
      playlistSongs.clear();

      for (var playlist in appPlaylists) {
        final songs = await audioQuery.queryAudiosFrom(
          AudiosFromType.PLAYLIST,
          playlist.id,
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
        );
        playlistSongs[playlist.id] = songs;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading playlists: $e');
      }
      Get.snackbar('Error', 'Failed to load playlists: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      final appPlaylistName = "$name $appPlaylistIdentifier";
      final result = await audioQuery.createPlaylist(appPlaylistName);
      if (result) {
        // await loadPlaylists();
        playlistSongs.refresh();
        await refreshPlaylists();
        Get.snackbar('Success', 'Playlist created successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create playlist: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      final result = await audioQuery.removePlaylist(playlistId);

      if (result) {
        // Refresh the entire playlists list
        await loadPlaylists();
        Get.snackbar('Success', 'Playlist deleted successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete playlist: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> renameMyPlaylist(int playlistId, String newName) async {
    try {
      if (kDebugMode) {
        print('Original name: $newName');
        print('Playlist ID: $playlistId');
      }

      // Make sure we're not duplicating the identifier
      final cleanName = newName.replaceAll(appPlaylistIdentifier, '').trim();
      final appPlaylistName = "$cleanName $appPlaylistIdentifier";

      if (kDebugMode) {
        print('New name: $appPlaylistName');
      }

      final result =
          await audioQuery.renamePlaylist(playlistId, appPlaylistName);

      if (result) {
        // Instead of reloading everything, just update the specific playlist
        final index =
            playlists.indexWhere((playlist) => playlist.id == playlistId);
        if (index != -1) {
          // Create a new playlist model with updated name (without the identifier)
          final updatedPlaylist = PlaylistModel(
              {...playlists[index].getMap, 'playlist': cleanName});

          // Update the list
          playlists[index] = updatedPlaylist;
          playlists.refresh();
        }

        Get.snackbar('Success', 'Playlist renamed successfully',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Error', 'Failed to rename playlist',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error renaming playlist: $e');
      }
      Get.snackbar('Error', 'Failed to rename playlist: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<bool> addToPlaylist(int playlistId, int songId) async {
    try {
      if (kDebugMode) {
        print('=== Debug: addToPlaylist ===');
        print('Adding song $songId to playlist $playlistId');
      }

      // Check if song already exists using cached data
      if (inInitialPlaylist(playlistId, songId)) {
        if (kDebugMode) {
          print('Song already exists in playlist');
        }
        return true; // Consider it a success if song is already there
      }

      final result = await audioQuery.addToPlaylist(playlistId, songId);

      if (kDebugMode) {
        print('Add to playlist result: $result');
      }

      // More permissive success check - any non-null, non-zero, non-false result is success
      final success = result.toString() != '0' &&
          result.toString().toLowerCase() != 'false';

      if (success) {
        // Find the song in our songs list
        final song = songs.firstWhere((s) => s.id == songId);

        if (kDebugMode) {
          print("SONG $song");
        }

        // Update local cache
        final currentSongs =
            List<SongModel>.from(playlistSongs[playlistId] ?? []);
        if (!currentSongs.any((s) => s.id == songId)) {
          currentSongs.add(song);
          playlistSongs[playlistId] = currentSongs;

          // Force UI update
          playlistSongs.refresh();
        }

        if (kDebugMode) {
          print('Successfully added song to playlist');
          print('Updated playlist size: ${currentSongs.length}');
        }

        // Update song count
        refreshPlaylistCount(playlistId);

        return true;
      }

      if (kDebugMode) {
        print('Failed to add song to playlist. Result: $result');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error in addToPlaylist: $e');
      }
      return false;
    }
  }

  Future<void> removeFromPlaylist(int playlistId, int songId) async {
    try {
      if (kDebugMode) {
        print('=== Debug: removeFromPlaylist ===');
        print('Playlist ID: $playlistId');
        print('Song ID to remove: $songId');
        print(
            'Current songs in playlist: ${playlistSongs[playlistId]?.map((s) => {
                  'id': s.id,
                  'title': s.title
                }).toList()}');
      }

      // First verify the song exists in the playlist
      final currentSongs = playlistSongs[playlistId] ?? [];
      final songIndex = currentSongs.indexWhere((song) => song.id == songId);

      if (songIndex == -1) {
        if (kDebugMode) {
          print('Song not found in playlist $songIndex');
        }
        Get.snackbar('Error', 'Song not found in playlist',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Remove from system playlist
      final result = await audioQuery.removeFromPlaylist(playlistId, songId);

      if (kDebugMode) {
        print('Remove result: $result');
      }

      // Parse result and check success
      final success =
          result.toString() == '1' || result.toString().toLowerCase() == 'true';

      if (success) {
        // Remove from our local playlist storage
        currentSongs.removeAt(songIndex);
        playlistSongs[playlistId] = currentSongs;

        // Force UI update
        playlistSongs.refresh();
        playlists.refresh();
        songCount.refresh();

        if (kDebugMode) {
          print('Successfully removed song');
          print(
              'Updated songs in playlist: ${playlistSongs[playlistId]?.map((s) => {
                    'id': s.id,
                    'title': s.title
                  }).toList()}');
        }

        Get.snackbar('Success', 'Song removed from playlist',
            snackPosition: SnackPosition.BOTTOM);

        // Update song count
        refreshPlaylistCount(playlistId);
      } else {
        if (kDebugMode) {
          print('Failed to remove song. Result: $result');
        }
        Get.snackbar('Error', 'Failed to remove song from playlist',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error removing song from playlist: $e');
        print('Stack trace: $stackTrace');
      }
      Get.snackbar('Error', 'Failed to remove song from playlist: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void refreshPlaylistCount(int playlistId) {
    songCount.value = playlistSongs[playlistId]?.length ?? 0;
  }

  Future<void> refreshPlaylists() async {
    await loadPlaylists();
  }

// Helper method to refresh playlist content
  Future<void> refreshPlaylist(int playlistId) async {
    try {
      if (kDebugMode) {
        print('=== Debug: refreshPlaylist ===');
        print('Refreshing playlist: $playlistId');
      }

      final songs = await audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      if (kDebugMode) {
        print('Fetched ${songs.length} songs for playlist');
      }

      playlistSongs[playlistId] = songs;
      playlistSongs.refresh();
      playlists.refresh();
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing playlist: $e');
      }
      Get.snackbar('Error', 'Failed to refresh playlist: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Simplified method to get playlist songs - now returns stored songs directly
  List<SongModel> getPlaylistSongs(int playlistId) {
    if (kDebugMode) {
      print('=== Debug: getPlaylistSongs ===');
      print('Playlist ID: $playlistId');
    }

    // Simply return the songs from the playlist without filtering
    final songs = playlistSongs[playlistId] ?? [];

    if (kDebugMode) {
      print('Returning ${songs.length} songs');
      for (var song in songs) {
        print('Song: ${song.title} - ${song.artist}');
      }
    }

    return songs;
  }

  bool isInPlaylist(int playlistId, String title) {
    try {
      final songs = playlistSongs[playlistId] ?? [];
      return songs.any((song) => song.title.trim() == title.trim());
    } catch (e) {
      if (kDebugMode) {
        print('Error in isInPlaylist: $e');
      }
      return false;
    }
  }

  bool inInitialPlaylist(int playlistId, int songId) {
    try {
      final songs = playlistSongs[playlistId] ?? [];
      return songs.any((song) => song.id == songId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in inInitialPlaylist: $e');
      }
      return false;
    }
  }

  Future<void> playPlaylist(int playlistId, {int startIndex = 0}) async {
    final playlistSongsList = getPlaylistSongs(playlistId);
    if (playlistSongsList.isNotEmpty) {
      playerController.currentPlaylist.value = playlistSongsList;
      await playerController.playSong(startIndex);
    }
  }

// Add other playlist-related methods here
}
