import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'lyrics_matcher.dart';
import 'lyrics_model.dart';

/// Outcome of an online lookup.
class LyricsLookupResult {
  /// The matching lyrics, or null when nothing matched.
  final LyricsModel? lyrics;

  /// True when the service could not be reached at all. A "no match" caused
  /// by being offline must not be remembered as "this song has no lyrics".
  final bool networkError;

  const LyricsLookupResult({this.lyrics, this.networkError = false});
}

/// Looks lyrics up on lrclib.net.
///
/// Instead of trusting one exact query (which misses whenever tags are
/// slightly off) it tries progressively looser queries and then verifies
/// every result with [LyricsMatcher] (title, artist and *duration*), so
/// timestamps line up with the file the user is actually playing.
class LyricsService {
  static const String _host = 'lrclib.net';
  static const Duration _timeout = Duration(seconds: 8);
  static const Map<String, String> _headers = {
    'User-Agent': 'Kanyoni/1.0 (https://github.com/munania/kanyoni)',
  };

  final http.Client _client;

  LyricsService({http.Client? client}) : _client = client ?? http.Client();

  Future<LyricsLookupResult> lookup(LyricsQuery q) async {
    var reachable = false;

    Future<dynamic> fetch(String path, Map<String, String> params) async {
      try {
        final response = await _client
            .get(Uri.https(_host, path, params), headers: _headers)
            .timeout(_timeout);
        if (response.statusCode == 200) {
          reachable = true;
          // Decode bytes as UTF-8 explicitly: without a charset header the
          // http package assumes Latin-1, which garbles accents and
          // non-Latin lyrics.
          return json.decode(utf8.decode(response.bodyBytes));
        }
        if (response.statusCode == 404) reachable = true;
      } catch (e) {
        if (kDebugMode) print('Lyrics request failed ($path): $e');
      }
      return null;
    }

    final titles = LyricsMatcher.titleVariants(q);
    final artists = LyricsMatcher.artistVariants(q);
    final durationInt = q.durationSec > 0 ? q.durationSec.round() : 0;
    final album = LyricsMatcher.isUnknown(q.album) ? '' : q.album.trim();

    // 1. Exact lookups (fast path for well-tagged files).
    final exactTried = <String>{};
    for (var i = 0; i < titles.length && i < 2; i++) {
      for (var j = 0; j < artists.length && j < 2; j++) {
        final key = '${titles[i]}|${artists[j]}';
        if (!exactTried.add(key)) continue;
        final data = await fetch('/api/get', {
          'track_name': titles[i],
          'artist_name': artists[j],
          if (album.isNotEmpty) 'album_name': album,
          if (durationInt > 0) 'duration': durationInt.toString(),
        });
        if (data is Map<String, dynamic>) {
          final model = LyricsModel.fromJson(data);
          final best = LyricsMatcher.pickBest([model], q);
          if (best != null) return LyricsLookupResult(lyrics: best);
        }
      }
    }

    // 2. Searches. Candidates are pooled so the best one across all
    //    queries wins.
    final pool = <LyricsModel>[];
    final seenIds = <int>{};

    Future<LyricsModel?> search(Map<String, String> params) async {
      final data = await fetch('/api/search', params);
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final model = LyricsModel.fromJson(item);
            if (model.id == 0 || seenIds.add(model.id)) pool.add(model);
          }
        }
      }
      return LyricsMatcher.pickBest(pool, q);
    }

    final mainArtist = artists.isNotEmpty ? artists.first : '';

    // 2a. Structured search with the cleaned title.
    var best = await search({
      'track_name': titles.first,
      if (mainArtist.isNotEmpty) 'artist_name': mainArtist,
    });
    if (best != null) return LyricsLookupResult(lyrics: best);

    // 2b. Free-text search ("title artist").
    best = await search({'q': '${titles.first} $mainArtist'.trim()});
    if (best != null) return LyricsLookupResult(lyrics: best);

    // 2c. Another title variant (brackets stripped / from file name).
    if (titles.length > 1) {
      best = await search({
        'track_name': titles[1],
        if (mainArtist.isNotEmpty) 'artist_name': mainArtist,
      });
      if (best != null) return LyricsLookupResult(lyrics: best);
    }

    // 2d. Title only; covers wrong or missing artist tags (the matcher still
    //     requires a near-identical length in that case).
    if (mainArtist.isNotEmpty) {
      best = await search({'q': titles.first});
      if (best != null) return LyricsLookupResult(lyrics: best);
    }

    return LyricsLookupResult(networkError: !reachable);
  }
}
