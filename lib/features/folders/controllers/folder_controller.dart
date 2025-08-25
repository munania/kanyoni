import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class FolderController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final PlayerController _playerController = Get.find<PlayerController>();
  final RxList<String> folders = <String>[].obs;
  final RxMap<String, List<SongModel>> folderSongs =
      <String, List<SongModel>>{}.obs;

  Future<void> fetchFolders() async {
    final List<String> allFolders = await audioQuery.queryAllPath();
    final List<String> blacklistedFolders = await getBlacklistedFolders();

    final List<String> filteredFolders = allFolders
        .where((folder) => !blacklistedFolders.contains(folder))
        .toList();

    folders.value = filteredFolders;
    await _loadSongsForFolders(filteredFolders);
  }

  Future<void> _loadSongsForFolders(List<String> folderList) async {
    for (String folder in folderList) {
      final songs = await audioQuery.querySongs(
        path: folder,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      folderSongs[folder] = await _playerController.applySongFilters(songs);
    }
  }

  List<SongModel> getFolderSongs(String folder) => folderSongs[folder] ?? [];

  int getSongCount(String folder) => getFolderSongs(folder).length;
}
