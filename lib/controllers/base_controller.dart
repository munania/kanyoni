import 'package:get/get.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

/// Lightweight base for the library controllers (albums, artists, genres,
/// playlists). It deliberately does NOT own an AudioPlayer: only
/// [PlayerController] does, so the app creates exactly one native player and
/// one equalizer instead of one per controller.
class BaseController extends GetxController {
  final OnAudioQuery audioQuery = OnAudioQuery();

  var songs = <SongModel>[].obs;
}
