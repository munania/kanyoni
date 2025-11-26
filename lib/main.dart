import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'controllers/media_player_handler.dart';
import 'controllers/player_controller.dart';
import 'features/albums/controller/album_controller.dart';
import 'features/artists/controller/artists_controller.dart';
import 'features/genres/controller/genres_controller.dart';
import 'features/playlists/controller/playlists_controller.dart';
import 'splash_screen.dart';
import 'utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(BaseController());
  Get.put(ThemeController());
  Get.put(PlaylistController());
  Get.put(AlbumController());
  Get.put(ArtistController());
  Get.put(GenreController());
  Get.put(PlayerController());
  Get.put(FolderController());

  await AudioService.init(
    builder: () => MediaPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.your.app.channel',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Get application document directory
  final appDir = await getApplicationDocumentsDirectory();

  // Initialize Hive and point it to that folder
  Hive.init(appDir.path);

  // Open a box (like a table in DB)
  await Hive.openBox('lyricsBox');

  runApp(const MyApp());
}

Future<bool> requestPermissions() async {
  // Request both permissions and return combined result
  // For Android 13+, we need separate permissions for audio and images/video if needed.
  // Permission.audio is generally for Android 13+ (API 33+).
  // Permission.storage is for older versions.

  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    Permission.audio,
    // Add notification permission for Android 13+
    Permission.notification,
  ].request();

  // Check if essential permissions are granted
  // On Android 13+, storage might be permanently denied or restricted, but audio is what matters for music.
  // On older Android, storage is key.

  bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
  bool audioGranted = statuses[Permission.audio]?.isGranted ?? false;

  // Simple logic: if either is granted, we might be okay depending on OS version.
  // But strictly, we want to ensure we can read files.

  if (storageGranted || audioGranted) {
    debugPrint('Permissions granted');
    return true;
  }

  debugPrint('Permissions denied');
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() {
      return GetMaterialApp(
        title: 'Kanyoni',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(themeController),
        darkTheme: AppTheme.darkTheme(themeController),
        themeMode: themeController.materialThemeMode,
        home: const SplashScreenPage(),
      );
    });
  }
}
