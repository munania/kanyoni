import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:path_provider/path_provider.dart';

import 'lyrics_model.dart';

/// A cache entry. [lyrics] == null means "we looked and found nothing".
class CachedLyrics {
  final LyricsModel? lyrics;
  const CachedLyrics(this.lyrics);
}

/// Local storage for lyrics, backed by Hive.
///
/// Why this does not slow the app down:
///  * Nothing is opened at start-up. The box is opened lazily, the first
///    time lyrics are needed (or in the background after the library has
///    loaded, see [warmUp]).
///  * It uses a [LazyBox]: only the keys live in memory, values (which are
///    several KB of text each) are read from disk on demand. Opening is
///    therefore O(number of keys), not O(size of all lyrics).
///
/// It stores three things per song id:
///  * `m:<id>` lyrics the user typed or pasted (never expire)
///  * `c:<id>` the lookup result from lrclib (or a "not found" marker)
///  * `o:<id>` the user's sync offset in milliseconds
class LyricsStore {
  LyricsStore._();
  static final LyricsStore instance = LyricsStore._();

  static const String _boxName = 'lyrics_v2';
  static const String _migratedKey = 'lyrics_migrated_to_hive_v2';
  static const String _legacyManualPrefix = 'manual_lyrics_';
  static const String _legacyCachePrefix = 'cached_lyrics_';

  /// Bump when matching logic changes so stale results are ignored.
  static const int cacheVersion = 2;

  /// Songs with no match are searched again after this long.
  static const Duration notFoundTtl = Duration(days: 3);

  Future<LazyBox<String>>? _opening;

  Future<LazyBox<String>> _open() =>
      _opening ??= _openInternal().catchError((Object e) {
        _opening = null; // allow a retry next time
        throw e;
      });

  Future<LazyBox<String>> _openInternal() async {
    final dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);

    LazyBox<String> box;
    try {
      box = await Hive.openLazyBox<String>(_boxName);
    } catch (e) {
      // A corrupted box must never break lyrics for good: start fresh.
      if (kDebugMode) print('Lyrics box corrupted, recreating: $e');
      await Hive.deleteBoxFromDisk(_boxName);
      box = await Hive.openLazyBox<String>(_boxName);
    }

    await _migrateFromPrefs(box);
    return box;
  }

  /// Opens the box ahead of time. Safe to call and forget.
  Future<void> warmUp() async {
    try {
      await _open();
    } catch (_) {}
  }

  /// One-time move of the old SharedPreferences data.
  ///  * Manual lyrics are kept (moved into Hive).
  ///  * Cached online lyrics are dropped: they were fetched with the old,
  ///    looser matching and may be for the wrong song.
  Future<void> _migrateFromPrefs(LazyBox<String> box) async {
    try {
      final p = await prefs;
      if (p.getBool(_migratedKey) ?? false) return;

      for (final key in p.getKeys().toList()) {
        if (key.startsWith(_legacyManualPrefix)) {
          final id = key.substring(_legacyManualPrefix.length);
          final value = p.getString(key);
          if (value != null && value.trim().isNotEmpty) {
            await box.put('m:$id', value);
          }
          await p.remove(key);
        } else if (key.startsWith(_legacyCachePrefix)) {
          await p.remove(key);
        }
      }
      await p.setBool(_migratedKey, true);
    } catch (e) {
      if (kDebugMode) print('Lyrics migration failed (will retry): $e');
    }
  }

  // --- manual lyrics ---------------------------------------------------------

  Future<String?> getManual(int songId) async {
    try {
      return await (await _open()).get('m:$songId');
    } catch (e) {
      if (kDebugMode) print('LyricsStore.getManual: $e');
      return null;
    }
  }

  Future<void> setManual(int songId, String lyrics) async {
    try {
      await (await _open()).put('m:$songId', lyrics);
    } catch (e) {
      if (kDebugMode) print('LyricsStore.setManual: $e');
    }
  }

  Future<void> deleteManual(int songId) async {
    try {
      await (await _open()).delete('m:$songId');
    } catch (e) {
      if (kDebugMode) print('LyricsStore.deleteManual: $e');
    }
  }

  // --- online lookup cache ---------------------------------------------------

  Future<CachedLyrics?> getCached(int songId) async {
    try {
      final raw = await (await _open()).get('c:$songId');
      if (raw == null) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      if (map['v'] != cacheVersion) return null;

      final lyricsJson = map['l'];
      if (lyricsJson is Map<String, dynamic>) {
        return CachedLyrics(LyricsModel.fromJson(lyricsJson));
      }

      // A "not found" marker: only trusted for a few days.
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        (map['t'] as num?)?.toInt() ?? 0,
      );
      if (DateTime.now().difference(savedAt) > notFoundTtl) return null;
      return const CachedLyrics(null);
    } catch (e) {
      if (kDebugMode) print('LyricsStore.getCached: $e');
      return null;
    }
  }

  /// Pass null to remember that nothing was found.
  Future<void> putCached(int songId, LyricsModel? lyrics) async {
    try {
      await (await _open()).put(
        'c:$songId',
        json.encode({
          'v': cacheVersion,
          't': DateTime.now().millisecondsSinceEpoch,
          'l': lyrics?.toJson(),
        }),
      );
    } catch (e) {
      if (kDebugMode) print('LyricsStore.putCached: $e');
    }
  }

  Future<void> deleteCached(int songId) async {
    try {
      await (await _open()).delete('c:$songId');
    } catch (e) {
      if (kDebugMode) print('LyricsStore.deleteCached: $e');
    }
  }

  // --- sync offset -----------------------------------------------------------

  Future<int> getOffset(int songId) async {
    try {
      final raw = await (await _open()).get('o:$songId');
      return int.tryParse(raw ?? '') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> setOffset(int songId, int offsetMs) async {
    try {
      final box = await _open();
      if (offsetMs == 0) {
        await box.delete('o:$songId');
      } else {
        await box.put('o:$songId', offsetMs.toString());
      }
    } catch (e) {
      if (kDebugMode) print('LyricsStore.setOffset: $e');
    }
  }
}
