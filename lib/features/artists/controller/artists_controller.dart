import 'dart:async';

import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class ArtistController extends BaseController {
  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxMap<int, List<SongModel>> artistSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  Future<void> fetchArtists() async {
    final artistsList = await audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    artists.value = artistsList;
    // Removed song pre-loading logic from here
  }

  Future<void> ensureSongsForArtistLoaded(int artistId) async {
    if (artistSongs[artistId] != null && artistSongs[artistId]!.isNotEmpty) {
      return; // Already loaded
    }
    // TODO: Consider adding isLoadingArtistSongs[artistId] = true; if UI needs it

    final queriedSongs = await audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      artistId,
      sortType: SongSortType.DATE_ADDED, // Or your preferred sort order
      orderType: OrderType.ASC_OR_SMALLER,
    );
    artistSongs[artistId] = queriedSongs;

    // TODO: Consider adding isLoadingArtistSongs[artistId] = false;
    artistSongs.refresh(); // Notify listeners
  }

  Future<void> playArtistSongs(int artistId) async {
    await ensureSongsForArtistLoaded(artistId); // Ensure songs are loaded
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
