import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaseController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  final AudioPlayer audioPlayer = AudioPlayer();
  late SharedPreferences _prefs;

  var songs = <SongModel>[].obs;
  var isDarkModeEnabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    isDarkModeEnabled.value = _prefs.getBool('darkModeStatus') ?? false;
  }

  Future<void> toggleDarkMode(bool value) async {
    await _prefs.setBool('darkModeStatus', value);
    isDarkModeEnabled.value = value;
  }
}
