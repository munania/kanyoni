import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/lyrics/lyrics_model.dart';
import 'package:kanyoni/features/lyrics/lyrics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyricsController extends GetxController {
  final LyricsService _lyricsService = LyricsService();
  final PlayerController _playerController = Get.find<PlayerController>();

  final Rx<LyricsModel?> currentLyrics = Rx<LyricsModel?>(null);
  final RxList<LyricLine> parsedLyrics = <LyricLine>[].obs;
  final RxInt currentLineIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _songSubscription;

  static const String _kManualLyricsKeyPrefix = 'manual_lyrics_';
  static const String _kCachedLyricsKeyPrefix = 'cached_lyrics_';

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to song changes
    _songSubscription = _playerController.currentSongIndex.listen((_) {
      _fetchLyricsForCurrentSong();
    });

    // Listen to player position for syncing
    _positionSubscription =
        _playerController.audioPlayer.positionStream.listen((position) {
      _syncLyrics(position);
    });
  }

  Future<void> _fetchLyricsForCurrentSong() async {
    final currentSong = _playerController.activeSong;
    if (currentSong == null) return;

    isLoading.value = true;
    hasError.value = false;
    currentLyrics.value = null;
    parsedLyrics.clear();
    currentLineIndex.value = 0;

    try {
      // Check for manual lyrics first
      final manualLyrics = await _getManualLyrics(currentSong.id);
      if (manualLyrics != null && manualLyrics.isNotEmpty) {
        currentLyrics.value = LyricsModel(
          id: currentSong.id,
          trackName: currentSong.title,
          artistName: currentSong.artist ?? '',
          albumName: currentSong.album ?? '',
          duration: (currentSong.duration ?? 0).toDouble(),
          instrumental: false,
          plainLyrics: manualLyrics,
          syncedLyrics: manualLyrics,
        );
        _parseLyrics(manualLyrics);
        isLoading.value = false;
        return;
      }

      // Check for cached lyrics
      final cachedLyrics = await _getCachedLyrics(currentSong.id);
      if (cachedLyrics != null) {
        currentLyrics.value = cachedLyrics;
        _parseLyrics(cachedLyrics.syncedLyrics);
        isLoading.value = false;
        return;
      }

      // Fetch from API if no manual or cached lyrics
      final lyrics = await _lyricsService.getLyrics(
        currentSong.title,
        currentSong.artist ?? '',
        (currentSong.duration ?? 0) / 1000, // Duration in seconds
      );

      if (lyrics != null) {
        currentLyrics.value = lyrics;
        _parseLyrics(lyrics.syncedLyrics);
        // 4. Cache the fetched lyrics
        _cacheLyrics(currentSong.id, lyrics);
      } else {
        hasError.value = true;
      }
    } catch (e) {
      hasError.value = true;
      if (kDebugMode) {
        print('Error in LyricsController: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _getManualLyrics(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_kManualLyricsKeyPrefix$songId');
  }

  Future<void> saveManualLyrics(String lyrics) async {
    final currentSong = _playerController.activeSong;
    if (currentSong == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kManualLyricsKeyPrefix${currentSong.id}', lyrics);

    // Reload lyrics to reflect changes
    _fetchLyricsForCurrentSong();
  }

  Future<void> deleteManualLyrics() async {
    final currentSong = _playerController.activeSong;
    if (currentSong == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kManualLyricsKeyPrefix${currentSong.id}');

    // Reload lyrics to reflect changes
    _fetchLyricsForCurrentSong();
  }

  Future<LyricsModel?> _getCachedLyrics(int songId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_kCachedLyricsKeyPrefix$songId');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap =
            Map<String, dynamic>.from(json.decode(jsonString));
        return LyricsModel.fromJson(jsonMap);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reading cached lyrics: $e');
      }
    }
    return null;
  }

  Future<void> _cacheLyrics(int songId, LyricsModel lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(lyrics.toJson());
      await prefs.setString('$_kCachedLyricsKeyPrefix$songId', jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching lyrics: $e');
      }
    }
  }

  void _parseLyrics(String syncedLyrics) {
    parsedLyrics.clear();
    if (syncedLyrics.isEmpty) return;

    final RegExp regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)');
    final lines = syncedLyrics.split('\n');

    for (final line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          parsedLyrics.add(LyricLine(
            time: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: milliseconds * 10,
            ),
            text: text,
          ));
        }
      }
    }
  }

  void _syncLyrics(Duration position) {
    if (parsedLyrics.isEmpty) return;

    // Add a small offset to make lyrics feel more responsive (look ahead)
    final syncPosition = position + const Duration(milliseconds: 650);

    // Find the current line based on timestamp
    int index = 0;
    for (int i = 0; i < parsedLyrics.length; i++) {
      if (syncPosition >= parsedLyrics[i].time) {
        index = i;
      } else {
        break;
      }
    }

    if (currentLineIndex.value != index) {
      currentLineIndex.value = index;
    }
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    _songSubscription?.cancel();
    super.onClose();
  }
}
