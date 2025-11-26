import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/features/settings/folder_blacklist.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class BehaviorSettingsScreen extends StatefulWidget {
  const BehaviorSettingsScreen({super.key});

  @override
  State<BehaviorSettingsScreen> createState() => _BehaviorSettingsScreenState();
}

class _BehaviorSettingsScreenState extends State<BehaviorSettingsScreen> {
  final PlayerController _playerController = Get.find<PlayerController>();
  final TextEditingController _lengthController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMinSongLength();
    _lengthController.addListener(_onTextChanged);
  }

  Future<void> _loadMinSongLength() async {
    final minLength = await getMinSongLength();
    _lengthController.text = minLength.toString();
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final newLength = int.tryParse(_lengthController.text) ?? 0;
      await saveMinSongLength(newLength);
      await _playerController.refreshSongs();
    });
  }

  @override
  void dispose() {
    _lengthController.removeListener(_onTextChanged);
    _lengthController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Behavior'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        // Get current song for background artwork
        final currentSongIndex = _playerController.currentSongIndex.value;
        final hasCurrentSong = currentSongIndex >= 0 &&
            currentSongIndex < _playerController.currentPlaylist.length;
        final currentSong = hasCurrentSong
            ? _playerController.currentPlaylist[currentSongIndex]
            : null;

        return Stack(
          children: [
            // Background Artwork with Blur
            RepaintBoundary(
              child: Stack(
                children: [
                  if (currentSong != null)
                    Positioned.fill(
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        quality: 100,
                        size: 1000,
                        artworkQuality: FilterQuality.high,
                        nullArtworkWidget: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ThemedArtworkPlaceholder(
                        iconSize: 120,
                      ),
                    ),
                  // Blur Effect
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(
                                alpha: isDarkMode ? 0.7 : 0.85,
                              ),
                          child: Container(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Minimum Song Length Card
                  _ModernSettingCard(
                    isDarkMode: isDarkMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Iconsax.timer_1,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Minimum Song Length',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Exclude songs shorter than this duration',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _lengthController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Duration (seconds)',
                                  hintText: '0',
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.grey[850]
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Folder Blacklist Card
                  _ModernSettingCard(
                    isDarkMode: isDarkMode,
                    onTap: () => Get.to(() => const FolderBlacklistScreen()),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.folder_minus,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Folder Blacklist',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Exclude songs from specific folders',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_right_3,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ModernSettingCard extends StatelessWidget {
  final bool isDarkMode;
  final Widget child;
  final VoidCallback? onTap;

  const _ModernSettingCard({
    required this.isDarkMode,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.02),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
