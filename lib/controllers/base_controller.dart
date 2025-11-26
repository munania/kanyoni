import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class BaseController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();
  late final AudioPlayer audioPlayer;
  AndroidEqualizer? androidEqualizer;

  BaseController() {
    if (GetPlatform.isAndroid) {
      androidEqualizer = AndroidEqualizer();
      print('[BaseController] AndroidEqualizer created');
    } else {
      print('[BaseController] Not Android, skipping equalizer');
    }

    audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          if (androidEqualizer != null) androidEqualizer!,
        ],
      ),
    );
    print(
        '[BaseController] AudioPlayer created with ${androidEqualizer != null ? "equalizer" : "no equalizer"}');
  }

  var songs = <SongModel>[].obs;
  var isDarkModeEnabled = false.obs;

  @override
  void onInit() async {
    super.onInit();
    isDarkModeEnabled.value = (await prefs).getBool('darkModeStatus') ?? false;
  }

  Future<void> toggleDarkMode(bool value) async {
    await (await prefs).setBool('darkModeStatus', value);
    isDarkModeEnabled.value = value;
  }
}
