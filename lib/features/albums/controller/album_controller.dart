import 'dart:async';

import 'package:get/get.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class AlbumController extends BaseController {
  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxMap<int, List<SongModel>> albumSongs = <int, List<SongModel>>{}.obs;
  final RxMap<int, bool> isLoadingAlbumSongs = <int, bool>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  Future<void> fetchAlbums() async {
    final albumsList = await audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    albums.value = albumsList;
    // Removed song pre-loading logic from here
  }

  Future<void> ensureSongsForAlbumLoaded(int albumId) async {
    if (albumSongs[albumId] != null && albumSongs[albumId]!.isNotEmpty) {
      return; // Already loaded
    }

    isLoadingAlbumSongs[albumId] = true;

    try {
      final queriedSongs = await audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        albumId,
        sortType: SongSortType.DATE_ADDED, // Or your preferred sort order
        orderType: OrderType.ASC_OR_SMALLER,
      );
      albumSongs[albumId] =
          await playerController.applySongFilters(queriedSongs);
    } finally {
      isLoadingAlbumSongs[albumId] = false;
    }

    albumSongs
        .refresh(); // Notify listeners if using Obx for the map directly or specific keys
  }

  Future<void> playAlbumSongs(int albumId) async {
    await ensureSongsForAlbumLoaded(
        albumId); // Ensure songs are loaded before playing
    final songs = getAlbumSongs(albumId);
    if (songs.isNotEmpty) {
      playerController.currentPlaylist.value = songs;
      await playerController.playSong(0);
    }
  }

  List<SongModel> getAlbumSongs(int albumId) {
    return albumSongs[albumId] ?? [];
  }
}
