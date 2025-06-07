import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/homepage.dart'; // Adjust import if needed
import 'package:kanyoni/main.dart'; // For AppLayout, requestPermissions
// import 'package:kanyoni/controllers/media_player_handler.dart'; // For AudioService - Not directly used here
import 'package:audio_service/audio_service.dart'; // For AudioService - Not directly used here, but good for context

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Get.put for controllers in main() should have already run.
    // AudioService.init in main() is also assumed to be awaited and completed.

    try {
      // 1. Request Permissions
      await requestPermissions(); // This is the function from main.dart

      // 2. Navigate to the main app
      // A small delay can make the splash screen visible briefly if init is too fast.
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      // Handle errors, maybe navigate to an error page or retry
      if (mounted) {
        Get.snackbar("Error", "Initialization failed: $e", snackPosition: SnackPosition.BOTTOM);
        // Optionally, navigate to an error screen or retry mechanism here
      }
    } finally {
      // Ensure navigation happens even if there was an error,
      // unless a specific error page is shown.
      if (mounted) {
        Get.off(() => const AppLayout(child: HomePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), // Or your app logo
            SizedBox(height: 20),
            Text('Loading Music...'),
          ],
        ),
      ),
    );
  }
}
