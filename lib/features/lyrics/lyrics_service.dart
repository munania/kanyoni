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
  static const Duration _timeout = Duration(seconds: 6);
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
    final mainArtist = artists.isNotEmpty ? artists.first : '';

    final pool = <LyricsModel>[];
    final seenIds = <int>{};

    /// One exact lookup. Returns the lyrics only if they really are this song.
    Future<LyricsModel?> exact(String title, String artist) async {
      try {
        final data = await fetch('/api/get', {
          'track_name': title,
          'artist_name': artist,
          if (album.isNotEmpty) 'album_name': album,
          if (durationInt > 0) 'duration': durationInt.toString(),
        });
        if (data is Map<String, dynamic>) {
          return LyricsMatcher.pickBest([LyricsModel.fromJson(data)], q);
        }
      } catch (_) {}
      return null;
    }

    /// One search. Candidates go into a shared pool; the best one is chosen
    /// once the searches are done.
    Future<void> search(Map<String, String> params) async {
      try {
        final data = await fetch('/api/search', params);
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              final model = LyricsModel.fromJson(item);
              if (model.id == 0 || seenIds.add(model.id)) pool.add(model);
            }
          }
        }
      } catch (_) {}
    }

    // Round 1: the exact lookup and two searches, all at the same time. The
    // old code ran them one after another, so a song that needed the second
    // or third query waited for every earlier request first.
    final exactMain = mainArtist.isEmpty
        ? Future<LyricsModel?>.value(null)
        : exact(titles.first, mainArtist);
    final structured = search({
      'track_name': titles.first,
      if (mainArtist.isNotEmpty) 'artist_name': mainArtist,
    });
    final freeText = search({'q': '${titles.first} $mainArtist'.trim()});

    final quickHit = await exactMain;
    if (quickHit != null) return LyricsLookupResult(lyrics: quickHit);

    await Future.wait([structured, freeText]);
    var best = LyricsMatcher.pickBest(pool, q);
    if (best != null) return LyricsLookupResult(lyrics: best);

    // Round 2: every remaining variant, again all at once.
    final tried = <String>{'${titles.first}|$mainArtist'};
    final exacts = <Future<LyricsModel?>>[];
    for (var i = 0; i < titles.length && i < 2; i++) {
      for (var j = 0; j < artists.length && j < 2; j++) {
        if (tried.add('${titles[i]}|${artists[j]}')) {
          exacts.add(exact(titles[i], artists[j]));
        }
      }
    }
    final searches = <Future<void>>[
      // Another title variant (brackets stripped / from the file name).
      if (titles.length > 1)
        search({
          'track_name': titles[1],
          if (mainArtist.isNotEmpty) 'artist_name': mainArtist,
        }),
      // Title only: covers a wrong or missing artist tag (the matcher still
      // demands a near-identical length in that case).
      if (mainArtist.isNotEmpty) search({'q': titles.first}),
    ];

    final exactResults = await Future.wait(exacts);
    await Future.wait(searches);
    for (final hit in exactResults) {
      if (hit != null) return LyricsLookupResult(lyrics: hit);
    }
    best = LyricsMatcher.pickBest(pool, q);
    if (best != null) return LyricsLookupResult(lyrics: best);

    return LyricsLookupResult(networkError: !reachable);
  }
}
