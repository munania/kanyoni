// views/tracks_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../utils/theme/theme.dart';

class TracksView extends StatelessWidget {
  const TracksView({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TracksList(
        isDarkMode: isDarkMode, playerController: playerController);
  }
}

class TracksList extends StatelessWidget {
  final PlayerController playerController;
  final bool isDarkMode;

  const TracksList({
    super.key,
    required this.isDarkMode,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: playerController.songs.length,
        itemBuilder: (context, index) {
          final song = playerController.songs[index];
          return ListTile(
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: Icon(
                size: 50,
                Iconsax.music,
                color: isDarkMode
                    ? AppTheme.playerControlsDark
                    : AppTheme.playerControlsLight,
              ),
            ),
            title: Text(
              song.title,
              style: AppTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist ?? 'Unknown Artist',
              style: AppTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => playerController.playSong(index),
          );
        },
      );
    });
  }
}
