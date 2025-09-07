import 'package:hive/hive.dart';

class LyricsDatabase {
  final String _boxName = "lyricsBox";

  // Open the Hive box
  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  // Save lyrics for a specific song ID
  Future<void> saveLyrics(int songId, String lyrics) async {
    final box = await _openBox();
    await box.put(songId, lyrics);
  }

  // Retrieve lyrics for a specific song ID
  Future<String?> getLyrics(int songId) async {
    final box = await _openBox();
    return box.get(songId);
  }

  // Delete lyrics for a specific song ID
  Future<void> deleteLyrics(int songId) async {
    final box = await _openBox();
    await box.delete(songId);
  }

  // Close the Hive box
  Future<void> closeBox() async {
    final box = await _openBox();
    await box.close();
  }
}
