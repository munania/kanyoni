import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:kanyoni/controllers/media_player_handler.dart';

/// Handles heavy initialization tasks in the background
class BackgroundInitializer {
  static AudioHandler? _audioHandler;
  static bool _isInitialized = false;
  static final _initCompleter = Completer<void>();

  /// Get the audio handler, initializing if needed
  static Future<AudioHandler> getAudioHandler() async {
    if (_audioHandler != null) return _audioHandler!;

    if (!_isInitialized) {
      await initialize();
    }

    return _audioHandler!;
  }

  /// Initialize AudioService in background
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print(
            '[BackgroundInitializer] Starting AudioService initialization...');
      }

      _audioHandler = await AudioService.init(
        builder: () => MediaPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.your.app.channel',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      _isInitialized = true;
      _initCompleter.complete();

      if (kDebugMode) {
        print('[BackgroundInitializer] AudioService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BackgroundInitializer] Error initializing AudioService: $e');
      }
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Wait for initialization to complete
  static Future<void> waitForInitialization() => _initCompleter.future;

  /// Check if already initialized
  static bool get isInitialized => _isInitialized;
}
