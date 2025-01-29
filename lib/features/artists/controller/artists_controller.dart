import 'dart:async';

import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class ArtistController extends BaseController {
  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxMap<int, List<SongModel>> artistSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  @override
  void onInit() async {
    super.onInit();
    loadArtists();
  }

  Future<void> loadArtists() async {
    final artistsList = await audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    artists.value = artistsList;

    final artistSongsList = await Future.wait(artistsList.map((artist) {
      return audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        artist.id,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
      );
    }));

    for (int i = 0; i < artistsList.length; i++) {
      artistSongs[artistsList[i].id] = artistSongsList[i];
    }
  }

  Future<void> playArtistSongs(int artistId) async {
    final songs = getArtistSongs(artistId);
    if (songs.isNotEmpty) {
      playerController.currentPlaylist.value = songs;
      await playerController.playSong(0);
    }
  }

  List<SongModel> getArtistSongs(int artistId) {
    return artistSongs[artistId] ?? [];
  }
}
