import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'splash_screen.dart';
import 'utils/lazy_controller_binding.dart';
import 'utils/theme/theme.dart';
import 'utils/background_initializer.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize lazy bindings - controllers only load when needed
  LazyControllerBinding().dependencies();

  // Start background initialization (non-blocking)
  // This runs in parallel while the UI loads
  BackgroundInitializer.initialize().catchError((e) {
    debugPrint('Background initialization error: $e');
  });

  // Initialize Hive asynchronously but don't block on opening boxes
  _initializeHive();

  runApp(const MyApp());
}

/// Initialize Hive database in background
Future<void> _initializeHive() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    // Open boxes lazily when needed instead of blocking startup
    await Hive.openBox('lyricsBox');
  } catch (e) {
    debugPrint('Hive initialization error: $e');
  }
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
