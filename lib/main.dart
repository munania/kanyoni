import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'controllers/media_player_handler.dart';
import 'controllers/player_controller.dart';
import 'features/albums/controller/album_controller.dart';
import 'features/artists/controller/artists_controller.dart';
import 'features/genres/controller/genres_controller.dart';
import 'features/playlists/controller/playlists_controller.dart';
import 'now_playing.dart';
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
  final storageGranted = await Permission.storage.request().isGranted;
  final audioGranted = await Permission.audio.request().isGranted;

  if (storageGranted && audioGranted) {
    debugPrint('All permissions granted');
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
        themeMode:
            themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreenPage(),
      );
    });
  }
}

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({
    super.key,
    required this.child,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late final PanelController
      panelController; // Use late final for single initialization

  @override
  void initState() {
    super.initState();
    panelController = PanelController(); // Initialize once in state
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: playerController,
        ),
        collapsed: CollapsedPanel(
          playerController: playerController,
          panelController: panelController,
        ),
        body: widget.child,
      ),
    );
  }
}
