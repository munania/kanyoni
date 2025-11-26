import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/app_layout.dart';
import 'package:kanyoni/homepage.dart';
import 'package:kanyoni/main.dart';
import 'package:permission_handler/permission_handler.dart';

import 'controllers/player_controller.dart';
import 'features/playlists/controller/playlists_controller.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  final playlistController = Get.find<PlaylistController>();
  bool _isError = false;
  String _errorMessage = '';
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isError = false;
      _showRetry = false;
    });

    try {
      // 1. Request Permissions
      final hasPermissions = await requestPermissions();

      if (!hasPermissions) {
        setState(() {
          _isError = true;
          _errorMessage = 'Storage permission is required to play music.';
          _showRetry = true;
        });
        return;
      }

      // 2. Navigate to the main app
      await Future.delayed(const Duration(milliseconds: 500));

      // Initialize your controllers after permissions
      final playerController = Get.find<PlayerController>();
      await playerController.fetchAllSongs();
      await playlistController.fetchPlaylists();

      if (mounted) {
        Get.off(() => const AppLayout(child: HomePage()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Initialization failed: $e';
          _showRetry = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 100.0),
            if (_isError) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
              if (_showRetry)
                ElevatedButton(
                  onPressed: () async {
                    if (_errorMessage.contains('permission')) {
                      await openAppSettings();
                    }
                    _initializeApp();
                  },
                  child: const Text('Open Settings / Retry'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
