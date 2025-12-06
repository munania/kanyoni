import 'dart:async';

import 'package:get/get.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class GenreController extends BaseController {
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxMap<int, List<SongModel>> genreSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, bool> isLoadingGenreSongs = <int, bool>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  Future<void> fetchGenres() async {
    final genreList = await audioQuery.queryGenres(
      sortType: GenreSortType.GENRE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    genres.value = genreList;
  }

  Future<void> ensureSongsForGenreLoaded(int genreId) async {
    if (genreSongs[genreId] != null && genreSongs[genreId]!.isNotEmpty) {
      return; // Already loaded
    }

    isLoadingGenreSongs[genreId] = true;

    try {
      final queriedSongs = await audioQuery.queryAudiosFrom(
        AudiosFromType.GENRE_ID,
        genreId,
        sortType: SongSortType.DATE_ADDED, // Or your preferred sort order
        orderType: OrderType.ASC_OR_SMALLER,
      );
      genreSongs[genreId] =
          await playerController.applySongFilters(queriedSongs);
    } finally {
      isLoadingGenreSongs[genreId] = false;
    }

    genreSongs.refresh(); // Notify listeners
  }

  List<SongModel> getGenreSongs(int genreId) {
    return genreSongs[genreId] ?? [];
  }

  Future<void> playGenreSongs(int genreId) async {
    await ensureSongsForGenreLoaded(genreId); // Ensure songs are loaded
    final songs = getGenreSongs(genreId);
    if (songs.isNotEmpty) {
      playerController.currentPlaylist.value = songs;
      await playerController.playSong(0);
    }
  }

  void filterGenres(String query) {
    if (query.isEmpty) {
      genres.refresh();
    } else {
      final lowerQuery = query.toLowerCase();
      genres.value = genres
          .where((genre) => genre.genre.toLowerCase().contains(lowerQuery))
          .toList();
    }
  }
}
