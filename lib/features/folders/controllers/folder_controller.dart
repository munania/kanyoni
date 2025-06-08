import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class FolderController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final RxList<String> folders = <String>[].obs;
  final RxMap<String, List<SongModel>> folderSongs =
      <String, List<SongModel>>{}.obs;

  Future<void> fetchFolders() async {
    final List<String> folderList = await audioQuery.queryAllPath();
    folders.value = folderList;
    await _loadSongsForFolders(folderList);
  }

  Future<void> _loadSongsForFolders(List<String> folderList) async {
    for (String folder in folderList) {
      final songs = await audioQuery.querySongs(
        path: folder,
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      folderSongs[folder] = songs;
    }
  }

  List<SongModel> getFolderSongs(String folder) => folderSongs[folder] ?? [];

  int getSongCount(String folder) => getFolderSongs(folder).length;
}
