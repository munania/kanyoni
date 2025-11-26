import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class ThemeSettingsView extends StatelessWidget {
  final ThemeController themeController = Get.find<ThemeController>();

  ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final PlayerController playerController = Get.find();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Theme Settings'),
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

        return Stack(children: [
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
              padding: const EdgeInsets.all(16),
              children: [
                // Theme Mode Section
                Text(
                  'Theme Mode',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

                Obx(() => _ThemeModeCard(
                      icon: Iconsax.mobile,
                      title: 'System',
                      subtitle: 'Follow device settings',
                      isSelected: themeController.themeMode.value == 'system',
                      isDarkMode: isDarkMode,
                      onTap: () => themeController.setThemeMode('system'),
                    )),
                const SizedBox(height: 8),

                Obx(() => _ThemeModeCard(
                      icon: Iconsax.sun_1,
                      title: 'Light',
                      subtitle: 'Always use light theme',
                      isSelected: themeController.themeMode.value == 'light',
                      isDarkMode: isDarkMode,
                      onTap: () => themeController.setThemeMode('light'),
                    )),
                const SizedBox(height: 8),

                Obx(() => _ThemeModeCard(
                      icon: Iconsax.moon,
                      title: 'Dark',
                      subtitle: 'Always use dark theme',
                      isSelected: themeController.themeMode.value == 'dark',
                      isDarkMode: isDarkMode,
                      onTap: () => themeController.setThemeMode('dark'),
                    )),

                const SizedBox(height: 32),

                // Theme Color Section
                Text(
                  'Theme Color',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

                // Color options grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: AppColors.themeColors.length,
                  itemBuilder: (context, index) {
                    final colorKey =
                        AppColors.themeColors.keys.elementAt(index);
                    final colorOption = AppColors.themeColors[colorKey]!;

                    return Obx(() => GestureDetector(
                          onTap: () =>
                              themeController.changeThemeColor(colorKey),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: themeController.themeColor.value ==
                                        colorKey
                                    ? Theme.of(context).primaryColor
                                    : (isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.02)),
                                width:
                                    themeController.themeColor.value == colorKey
                                        ? 2
                                        : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: themeController.isDarkMode
                                          ? colorOption.dark
                                          : colorOption.light,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            themeController.themeColor.value ==
                                                    colorKey
                                                ? (isDarkMode
                                                    ? Colors.white
                                                    : Colors.black)
                                                : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: themeController.themeColor.value ==
                                            colorKey
                                        ? Icon(
                                            Iconsax.tick_circle5,
                                            color: isDarkMode
                                                ? Colors.black
                                                : Colors.white,
                                            size: 28,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    colorOption.name,
                                    style: AppTheme.bodyMedium.copyWith(
                                      fontWeight:
                                          themeController.themeColor.value ==
                                                  colorKey
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                  },
                ),

                const SizedBox(height: 32),

                // Waveform Style Section
                Text(
                  'Waveform Style',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),

                Obx(() => Column(
                      children: [
                        _WaveformStyleCard(
                          title: 'Polygon',
                          subtitle: 'Standard polygon waveform',
                          isSelected:
                              themeController.waveformStyle.value == 'Polygon',
                          isDarkMode: isDarkMode,
                          onTap: () =>
                              themeController.setWaveformStyle('Polygon'),
                        ),
                        const SizedBox(height: 8),
                        _WaveformStyleCard(
                          title: 'Rectangle',
                          subtitle: 'Clean rectangular bars',
                          isSelected: themeController.waveformStyle.value ==
                              'Rectangle',
                          isDarkMode: isDarkMode,
                          onTap: () =>
                              themeController.setWaveformStyle('Rectangle'),
                        ),
                        const SizedBox(height: 8),
                        _WaveformStyleCard(
                          title: 'Squiggly',
                          subtitle: 'Fun squiggly lines',
                          isSelected:
                              themeController.waveformStyle.value == 'Squiggly',
                          isDarkMode: isDarkMode,
                          onTap: () =>
                              themeController.setWaveformStyle('Squiggly'),
                        ),
                        const SizedBox(height: 8),
                        _WaveformStyleCard(
                          title: 'Curved',
                          subtitle: 'Smooth curved polygon',
                          isSelected:
                              themeController.waveformStyle.value == 'Curved',
                          isDarkMode: isDarkMode,
                          onTap: () =>
                              themeController.setWaveformStyle('Curved'),
                        ),
                      ],
                    )),
              ],
            ),
          )
        ]);
      }),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
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
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02)),
          width: isSelected ? 2 : 1,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
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
                if (isSelected)
                  Icon(
                    Iconsax.tick_circle5,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformStyleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _WaveformStyleCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
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
          color: isSelected
              ? Theme.of(context).primaryColor
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02)),
          width: isSelected ? 2 : 1,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.music_dashboard,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
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
                if (isSelected)
                  Icon(
                    Iconsax.tick_circle5,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
