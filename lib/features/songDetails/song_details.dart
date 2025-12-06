import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class SongDetails extends StatelessWidget {
  final SongModel currentSong;

  const SongDetails({super.key, required this.currentSong});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    String formatDuration(int raw) {
      Duration d = Duration(milliseconds: raw);
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String minutes = twoDigits(d.inMinutes.remainder(60));
      String seconds = twoDigits(d.inSeconds.remainder(60));
      return "$minutes:$seconds";
    }

    String songSize(int size) {
      int kb = 1024;
      double songSize = (size / (kb * kb));
      return songSize.toStringAsFixed(2);
    }

    String durationString = formatDuration(currentSong.duration ?? 0);
    String songSizeString = songSize(currentSong.size);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.arrow_left,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Details',
          style: AppTheme.headlineMedium.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Artwork with Blur
          Positioned.fill(
            child: QueryArtworkWidget(
              id: currentSong.id,
              type: ArtworkType.AUDIO,
              quality: 100,
              size: 1000,
              artworkQuality: FilterQuality.high,
              nullArtworkWidget: Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: isDarkMode ? 0.7 : 0.85,
                    ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Artwork
                  Hero(
                    tag: 'details_artwork',
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: QueryArtworkWidget(
                          id: currentSong.id,
                          type: ArtworkType.AUDIO,
                          quality: 100,
                          size: 1000,
                          artworkQuality: FilterQuality.high,
                          nullArtworkWidget: Container(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Iconsax.music,
                              size: 120,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Details List
                  _buildDetailCard(
                    context,
                    title: 'Track Information',
                    children: [
                      DetailsWidget(
                        icon: Iconsax.music,
                        label: 'Title',
                        value: currentSong.title,
                      ),
                      const SizedBox(height: 16),
                      DetailsWidget(
                        icon: Iconsax.user,
                        label: 'Artist',
                        value: currentSong.artist ?? 'Unknown Artist',
                      ),
                      const SizedBox(height: 16),
                      DetailsWidget(
                        icon: Iconsax.record,
                        label: 'Album',
                        value: currentSong.album ?? 'Unknown Album',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildDetailCard(
                    context,
                    title: 'File Properties',
                    children: [
                      DetailsWidget(
                        icon: Iconsax.timer_1,
                        label: 'Duration',
                        value: durationString,
                      ),
                      const SizedBox(height: 16),
                      DetailsWidget(
                        icon: Iconsax.folder_open,
                        label: 'File Size',
                        value: '$songSizeString MB',
                      ),
                      const SizedBox(height: 16),
                      DetailsWidget(
                        icon: Iconsax.document,
                        label: 'Format',
                        value: currentSong.fileExtension.toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class DetailsWidget extends StatelessWidget {
  const DetailsWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
