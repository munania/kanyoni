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

  // Keep  albums and artists, genres
  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxList<GenreModel> genres = <GenreModel>[].obs;

  // Maps to store songs by album and artist
  final RxMap<int, List<SongModel>> albumSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, List<SongModel>> artistSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, List<SongModel>> genreSongs = <int, List<SongModel>>{}.obs;

  // original playlist
  List<SongModel>? originalPlaylist;

  @override
  void onInit() {
    super.onInit();
    loadSongs();
    _initializeAudioPlayer();
    loadAlbums();
    loadArtists();
    loadGenres();
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
      currentPlaylist.value = songs;
    } catch (e) {
      Get.snackbar("Error", "Failed to load songs: $e");
    }
  }

  Future<void> playSong(int index) async {
    if (index >= 0 && index < currentPlaylist.length) {
      final songUri = currentPlaylist[index].uri;
      if (songUri != null) {
        currentSongIndex.value = index;
        await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(songUri)));
        audioPlayer.play();
      } else {
        Get.snackbar("Error", "Cannot play song. URI is null.");
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
