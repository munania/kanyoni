import 'package:get/get.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';

/// Lazy binding for all app controllers
/// Controllers are only initialized when first accessed, improving startup time
class LazyControllerBinding extends Bindings {
  @override
  void dependencies() {
    // Core controllers - initialized immediately but lightweight
    Get.lazyPut<BaseController>(() => BaseController(), fenix: true);
    Get.lazyPut<ThemeController>(() => ThemeController(), fenix: true);

    // Feature controllers - only initialized when needed
    Get.lazyPut<PlayerController>(() => PlayerController(), fenix: true);
    Get.lazyPut<PlaylistController>(() => PlaylistController(), fenix: true);
    Get.lazyPut<AlbumController>(() => AlbumController(), fenix: true);
    Get.lazyPut<ArtistController>(() => ArtistController(), fenix: true);
    Get.lazyPut<GenreController>(() => GenreController(), fenix: true);
    Get.lazyPut<FolderController>(() => FolderController(), fenix: true);
  }
}
