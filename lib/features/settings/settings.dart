import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/base_controller.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/features/settings/behavior_settings.dart';
// import 'package:kanyoni/features/settings/policies_settings.dart';
import 'package:kanyoni/features/settings/support_settings.dart';
import 'package:kanyoni/features/settings/theme_settings.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final BaseController baseController = Get.find<BaseController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final PlayerController playerController = Get.find();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        // Get current song for background artwork
        final currentSongIndex = playerController.currentSongIndex.value;
        final hasCurrentSong = currentSongIndex >= 0 &&
            currentSongIndex < playerController.currentPlaylist.length;
        final currentSong = hasCurrentSong
            ? playerController.currentPlaylist[currentSongIndex]
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _ModernSettingsCard(
                      icon: Iconsax.activity,
                      title: 'Behavior',
                      subtitle: 'Customize app behavior',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Get.to(() => const BehaviorSettingsScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    _ModernSettingsCard(
                      icon: Iconsax.color_swatch,
                      title: 'Theme Settings',
                      subtitle: 'Customize app appearance',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Get.to(() => ThemeSettingsView());
                      },
                    ),
                    const SizedBox(height: 12),
                    // _ModernSettingsCard(
                    //   icon: Iconsax.shield_tick,
                    //   title: 'Policies',
                    //   subtitle: 'Privacy policy and terms',
                    //   isDarkMode: isDarkMode,
                    //   onTap: () {
                    //     Get.to(() => const PoliciesSettingsScreen());
                    //   },
                    // ),
                    const SizedBox(height: 12),
                    _ModernSettingsCard(
                      icon: Iconsax.support,
                      title: 'Support',
                      subtitle: 'Rate app and send feedback',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Get.to(() => const SupportSettingsScreen());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ModernSettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ModernSettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDarkMode,
    required this.onTap,
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
