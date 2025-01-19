import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class AlbumController extends BaseController {
  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxMap<int, List<SongModel>> albumSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  @override
  void onInit() {
    super.onInit();
    loadAlbums();
  }

  Future<void> loadAlbums() async {
    final albumsList = await audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );
    albums.value = albumsList;

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

  Future<void> playAlbumSongs(int albumId) async {
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
