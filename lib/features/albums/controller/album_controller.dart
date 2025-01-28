import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class AlbumController extends BaseController {
  Timer? _scrollDebounceTimer;
  late SharedPreferences _prefs;

  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxMap<int, List<SongModel>> albumSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  static const String kLastAppCloseTimeKey = 'albums_last_app_close_time';
  static const Duration kScrollPositionRestoreThreshold = Duration(minutes: 30);

  var listScrollOffset = 0.0.obs;
  int? get lastAppCloseTime => _prefs.getInt(kLastAppCloseTimeKey);

  Future<void> _saveState() async {
    try {
      await _prefs.setInt(
          kLastAppCloseTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving app closure time: $e');
      }
    }
  }

  bool shouldRestoreScrollPosition() {
    final lastCloseTime = lastAppCloseTime;
    if (lastCloseTime == null) return false;

    final timeSinceClose = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastCloseTime));

    return timeSinceClose < kScrollPositionRestoreThreshold;
  }

  void updateListScrollPosition(double offset) {
    listScrollOffset.value = offset;
    _debouncedSaveState();
  }

  void _debouncedSaveState() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(seconds: 1), _saveState);
  }

  @override
  void onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
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
