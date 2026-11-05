import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

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
    // Query all folders concurrently instead of one after the other.
    final results = await Future.wait(folderList.map((folder) async {
      final songs = await audioQuery.querySongs(
        path: folder,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      return MapEntry(folder, await _playerController.applySongFilters(songs));
    }));
    folderSongs.addEntries(results);
  }

  List<SongModel> getFolderSongs(String folder) => folderSongs[folder] ?? [];

  int getSongCount(String folder) => getFolderSongs(folder).length;
}
