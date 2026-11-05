import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  // Note: Hive (used for the lyrics cache) is intentionally NOT initialised
  // here. It is opened lazily the first time lyrics are needed, so it adds
  // nothing to app start-up. See LyricsStore.

  runApp(const MyApp());
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
