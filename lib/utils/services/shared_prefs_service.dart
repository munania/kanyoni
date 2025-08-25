import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _prefsInstance;

const String kMinSongLengthKey = 'min_song_length';
const String kBlacklistedFoldersKey = 'blacklisted_folders';

Future<SharedPreferences> get prefs async {
  _prefsInstance ??= await SharedPreferences.getInstance();
  return _prefsInstance!;
}

Future<void> saveMinSongLength(int seconds) async {
  final prefsInstance = await prefs;
  await prefsInstance.setInt(kMinSongLengthKey, seconds);
}

Future<int> getMinSongLength() async {
  final prefsInstance = await prefs;
  return prefsInstance.getInt(kMinSongLengthKey) ?? 0;
}

Future<void> saveBlacklistedFolders(List<String> folders) async {
  final prefsInstance = await prefs;
  await prefsInstance.setStringList(kBlacklistedFoldersKey, folders);
}

Future<List<String>> getBlacklistedFolders() async {
  final prefsInstance = await prefs;
  return prefsInstance.getStringList(kBlacklistedFoldersKey) ?? [];
}
