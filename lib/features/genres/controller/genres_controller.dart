import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/base_controller.dart';

class GenreController extends BaseController {
  Timer? _scrollDebounceTimer;
  late SharedPreferences _prefs;

  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxMap<int, List<SongModel>> genreSongs = <int, List<SongModel>>{}.obs;
  PlayerController playerController = Get.find<PlayerController>();

  static const String kLastAppCloseTimeKey = 'genres_last_app_close_time';
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
