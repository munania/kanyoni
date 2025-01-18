import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:rxdart/rxdart.dart' show CombineLatestStream;

class MusicPlayerController extends GetxController {
  final audioQuery = OnAudioQuery();
  final audioPlayer = AudioPlayer();

  var songs = <SongModel>[].obs;
  var currentSongIndex = 0.obs;
  var isPlaying = false.obs;
  var isShuffle = false.obs;
  var repeatMode = RepeatMode.off.obs;
  var favoriteSongs = <int>[].obs;
  var currentPlaylist = <SongModel>[].obs;
  var volume = 1.0.obs;
  RxInt songCount = 0.obs;

  // Keep  albums and artists, genres
  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;

  // Maps to store songs by album and artist
  final RxMap<int, List<SongModel>> albumSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, List<SongModel>> artistSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, List<SongModel>> genreSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, List<SongModel>> playlistSongs =
      <int, List<SongModel>>{}.obs;

  // original playlist
  List<SongModel>? originalPlaylist;

  @override
  void onInit() {
    super.onInit();
    loadSongs().then((_) {
      loadPlaylists();
      loadAlbums();
      loadArtists();
      loadGenres();
    });
    _initializeAudioPlayer();
  }

  Future<void> loadPlaylists() async {
    try {
      if (kDebugMode) {
        print('=== Debug: loadPlaylists ===');
      }

      final List<PlaylistModel> loadedPlaylists =
          await audioQuery.queryPlaylists(
        sortType: PlaylistSortType.PLAYLIST,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      if (kDebugMode) {
        print('Loaded playlists count: ${loadedPlaylists.length}');
      }

      playlists.value = loadedPlaylists;

      // Clear existing playlist songs
      playlistSongs.clear();

      // Load songs for each playlist
      for (var playlist in loadedPlaylists) {
        if (kDebugMode) {
          print(
              'Loading songs for playlist: ${playlist.playlist} (ID: ${playlist.id})');
        }

        // Direct query for playlist songs
        final songs = await audioQuery.queryAudiosFrom(
          AudiosFromType.PLAYLIST,
          playlist.id,
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
        );

        if (kDebugMode) {
          print('Found ${songs.length} songs in playlist ${playlist.id}');
          print('Song details: ${songs.map((s) => {
                'id': s.id,
                'title': s.title
              }).toList()}');
        }

        // Store the complete SongModel objects
        playlistSongs[playlist.id] = songs;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading playlists: $e');
        print(e.toString());
      }
      Get.snackbar('Error', 'Failed to load playlists: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      final result = await audioQuery.createPlaylist(name);
      final playlistId = int.tryParse(result.toString());

      if (playlistId != null && playlistId != 0) {
        // Refresh the entire playlists list
        await loadPlaylists();
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
      final success = int.tryParse(result.toString()) ?? 0;

      if (success == 1) {
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

  Future<void> renamePlaylist(int playlistId, String newName) async {
    try {
      final result = await audioQuery.renamePlaylist(playlistId, newName);
      final success = int.tryParse(result.toString()) ?? 0;

      if (success == 1) {
        // Refresh the entire playlists list
        await loadPlaylists();
        Get.snackbar('Success', 'Playlist renamed successfully',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
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

    final playlistSongs = this.playlistSongs[playlistId] ?? [];

    // Filter out any songs that don't exist in the main songs list
    final validSongs = playlistSongs.where((playlistSong) {
      return songs.any((mainSong) =>
          mainSong.title == playlistSong.title &&
          mainSong.artist == playlistSong.artist);
    }).toList();

    if (kDebugMode) {
      print('Found ${validSongs.length} valid songs in playlist');
    }

    return validSongs;
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
      currentPlaylist.value = playlistSongsList;
      await playSong(startIndex);
    }
  }

  Future<void> loadAlbums() async {
    final albumsList = await audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    albums.value = albumsList;

    // Fetch songs for all albums in parallel
    final albumSongsList = await Future.wait(albumsList.map((album) {
      return audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        album.id,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    }));

    for (int i = 0; i < albumsList.length; i++) {
      albumSongs[albumsList[i].id] = albumSongsList[i];
    }
  }

  Future<void> loadArtists() async {
    final artistsList = await audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    artists.value = artistsList;

    // Fetch songs for all artists in parallel
    final artistSongsList = await Future.wait(artistsList.map((artists) {
      return audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        artists.id,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    }));

    for (int i = 0; i < artistsList.length; i++) {
      artistSongs[artistsList[i].id] = artistSongsList[i];
    }
  }

  Future<void> loadGenres() async {
    final genreList = await audioQuery.queryGenres(
      sortType: GenreSortType.GENRE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    genres.value = genreList;

    // Fetch songs for all genres in parallel
    final genreSongsList = await Future.wait(genreList.map((genre) {
      return audioQuery.queryAudiosFrom(
        AudiosFromType.GENRE_ID,
        genre.id,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    }));

    for (int i = 0; i < genreList.length; i++) {
      genreSongs[genreList[i].id] = genreSongsList[i];
    }
  }

  // Helper methods for albums and artists
  List<SongModel> getAlbumSongs(int albumId) {
    return albumSongs[albumId] ?? [];
  }

  List<SongModel> getArtistSongs(int artistId) {
    return artistSongs[artistId] ?? [];
  }

  List<SongModel> getGenreSongs(int genreId) {
    return genreSongs[genreId] ?? [];
  }

  Future<void> playAlbumSongs(int albumId) async {
    final songs = getAlbumSongs(albumId);
    if (songs.isNotEmpty) {
      currentPlaylist.value = songs;
      await playSong(0);
    }
  }

  Future<void> playArtistSongs(int artistId) async {
    final songs = getArtistSongs(artistId);
    if (songs.isNotEmpty) {
      currentPlaylist.value = songs;
      await playSong(0);
    }
  }

  Future<void> playGenreSongs(int genreId) async {
    final songs = getGenreSongs(genreId);
    if (songs.isNotEmpty) {
      currentPlaylist.value = songs;
      await playSong(0);
    }
  }

  // Rest of the controller methods
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
      } // Debug print
      currentPlaylist.value = songs;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading songs: $e');
      } // Debug print
      Get.snackbar("Error", "Failed to load songs: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> playSong(dynamic input) async {
    int index;
    SongModel songToPlay;

    if (input is SongModel) {
      songToPlay = input;
      // Find song in current playlist
      index = currentPlaylist.indexWhere((song) =>
          song.title == songToPlay.title && song.artist == songToPlay.artist);

      if (index == -1) {
        // If song isn't in current playlist, add it
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
        // Find the corresponding song in the main songs list
        final mainSong = songs.firstWhereOrNull((s) =>
            s.title == songToPlay.title && s.artist == songToPlay.artist);

        // Use the main song's URI if available, otherwise use the playlist song
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

  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void filterGenres(String query) {
    if (query.isEmpty) {
      genres.refresh(); // Reset to original genres
    } else {
      final lowerQuery = query.toLowerCase();
      genres.value = genres
          .where((genre) => genre.genre.toLowerCase().contains(lowerQuery))
          .toList();
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
