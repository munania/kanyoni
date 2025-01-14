// lib/main.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'controllers/music_player_controller.dart';
import 'homepage.dart';
import 'now_playing.dart'; // Your separated now playing components
import 'utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
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
    return GetMaterialApp(
      title: 'Music Player',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppLayout(
        child: HomePage(),
      ),
    );
  }
}

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MusicPlayerController());
    final panelController = PanelController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          controller: controller,
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          controller: controller,
          isDarkMode: isDarkMode,
        ),
        body: child,
      ),
    );
  }
}
