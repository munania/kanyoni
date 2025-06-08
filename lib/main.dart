import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'controllers/media_player_handler.dart';
import 'controllers/player_controller.dart';
import 'features/albums/controller/album_controller.dart';
import 'features/artists/controller/artists_controller.dart';
import 'features/genres/controller/genres_controller.dart';
import 'features/playlists/controller/playlists_controller.dart';
import 'homepage.dart';
import 'now_playing.dart';
import 'splash_screen.dart'; // Added import for splash screen
import 'utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(BaseController());
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
  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  // Request storage permissions
  if (await Permission.storage.request().isGranted) {
    debugPrint('Storage permission granted');
  } else {
    debugPrint('Storage permission denied');
  }

  // For Android 13 and above, we need additional media permissions
  if (await Permission.audio.request().isGranted) {
    debugPrint('Audio permission granted');
  } else {
    debugPrint('Audio permission denied');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    BaseController baseController = Get.find<BaseController>();

    return Obx(() {
      return GetMaterialApp(
        title: 'Kanyoni',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: baseController.isDarkModeEnabled.value
            ? ThemeMode.dark
            : ThemeMode.light,
        home: const SplashScreenPage(), // Home is now SplashScreenPage
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
    // requestPermissions(); // Removed this line
    panelController = PanelController(); // Initialize once in state
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final isDarkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        // Use the state-maintained controller
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: playerController,
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          playerController: playerController,
          isDarkMode: isDarkMode,
          panelController: panelController,
        ),
        body: widget.child,
      ),
    );
  }
}
