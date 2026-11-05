import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:kanyoni/controllers/media_player_handler.dart';

/// Handles heavy initialization tasks in the background
class BackgroundInitializer {
  static AudioHandler? _audioHandler;
  static Future<void>? _initFuture;

  /// Get the audio handler, initializing if needed
  static Future<AudioHandler> getAudioHandler() async {
    await initialize();
    return _audioHandler!;
  }

  /// Initialize AudioService in background.
  ///
  /// The future is memoised, so concurrent callers share one initialisation.
  /// If it fails the memo is cleared so the splash screen's Retry button can
  /// try again (previously a second attempt completed the same Completer
  /// twice and threw a StateError).
  static Future<void> initialize() => _initFuture ??= _doInitialize();

  static Future<void> _doInitialize() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => MediaPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.kanyoni.channel.audio',
          androidNotificationChannelName: 'Music Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('[BackgroundInitializer] Error initializing AudioService: $e');
      }
      _initFuture = null;
      rethrow;
    }
  }

  /// Wait for initialization to complete
  static Future<void> waitForInitialization() => initialize();

  /// Check if already initialized
  static bool get isInitialized => _audioHandler != null;
}
