import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kanyoni/features/lyrics/lyrics_model.dart';

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';

  Future<LyricsModel?> getLyrics(
      String trackName, String artistName, double duration) async {
    try {
      final uri = Uri.parse('$_baseUrl/get').replace(queryParameters: {
        'track_name': trackName,
        'artist_name': artistName,
        'duration': duration.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LyricsModel.fromJson(data);
      } else if (response.statusCode == 404) {
        // Try searching if exact match fails
        return _searchLyrics(trackName, artistName);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching lyrics: $e');
      }
    }
    return null;
  }

  Future<LyricsModel?> _searchLyrics(
      String trackName, String artistName) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': '$trackName $artistName',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Return the first result
          return LyricsModel.fromJson(data.first);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching lyrics: $e');
      }
    }
    return null;
  }
}
