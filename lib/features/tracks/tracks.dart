// views/tracks_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';

class TracksView extends StatelessWidget {
  const TracksView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TracksList(controller: controller, isDarkMode: isDarkMode);
  }
}

class TracksList extends StatelessWidget {
  final MusicPlayerController controller;
  final bool isDarkMode;

  const TracksList({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        itemCount: controller.songs.length,
        itemBuilder: (context, index) {
          final song = controller.songs[index];
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
            // trailing: IconButton(
            //   icon: Icon(
            //     controller.favoriteSongs.contains(song.id)
            //         ? Icons.favorite
            //         : Icons.favorite_border,
            //     color: controller.favoriteSongs.contains(song.id)
            //         ? AppTheme.playerControlsDark
            //         : null,
            //   ),
            //   onPressed: () => controller.toggleFavorite(song.id),
            // ),
            onTap: () => controller.playSong(index),
          );
        },
      );
    });
  }
}
