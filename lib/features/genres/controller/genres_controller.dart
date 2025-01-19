import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';

class GenreController extends BaseController {
  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxMap<int, List<SongModel>> genreSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  @override
  void onInit() {
    super.onInit();
    loadGenres();
  }

  Future<void> loadGenres() async {
    final genreList = await audioQuery.queryGenres(
      sortType: GenreSortType.GENRE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    genres.value = genreList;

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

  List<SongModel> getGenreSongs(int genreId) {
    return genreSongs[genreId] ?? [];
  }

  Future<void> playGenreSongs(int genreId) async {
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
