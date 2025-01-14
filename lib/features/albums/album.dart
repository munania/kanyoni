// views/albums_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';
import 'albums_details.dart';

class AlbumsView extends StatelessWidget {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: controller.albums.length,
        itemBuilder: (context, index) {
          final album = controller.albums[index];
          return AlbumCard(
            album: album,
            isDarkMode: isDarkMode,
            onTap: () => Get.to(() => AlbumDetailsView(album: album)),
          );
        },
      );
    });
  }
}

class AlbumCard extends StatelessWidget {
  final AlbumModel album;
  final bool isDarkMode;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.cornerRadius),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: QueryArtworkWidget(
                  id: album.id,
                  type: ArtworkType.ALBUM,
                  nullArtworkWidget: Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Iconsax.music_square,
                      size: 50,
                      color: isDarkMode
                          ? AppTheme.playerControlsDark
                          : AppTheme.playerControlsLight,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.artist ?? 'Unknown Artist',
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.numOfSongs} songs',
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
