import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/base_controller.dart';
import '../../../controllers/player_controller.dart';

class ArtistController extends BaseController {
  Timer? _scrollDebounceTimer;
  late SharedPreferences _prefs;

  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxMap<int, List<SongModel>> artistSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  static const String kLastAppCloseTimeKey = 'artists_last_app_close_time';
  static const Duration kScrollPositionRestoreThreshold = Duration(minutes: 30);

  var listScrollOffset = 0.0.obs;

  int? get lastAppCloseTime => _prefs.getInt(kLastAppCloseTimeKey);

  Future<void> _saveState() async {
    try {
      await _prefs.setInt(
          kLastAppCloseTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print("Error saving app closure time: $e");
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
