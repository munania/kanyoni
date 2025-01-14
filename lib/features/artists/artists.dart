import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';
import 'artists_details.dart';

class ArtistsView extends StatelessWidget {
  const ArtistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.artists.length,
        itemBuilder: (context, index) {
          final artist = controller.artists[index];
          return ArtistCard(
            artist: artist,
            isDarkMode: isDarkMode,
            onTap: () => Get.to(() => ArtistsDetailsView(artist: artist)),
          );
        },
      );
    });
  }
}

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final bool isDarkMode;
  final VoidCallback onTap;

  const ArtistCard({
    super.key,
    required this.artist,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: QueryArtworkWidget(
                    id: artist.id,
                    type: ArtworkType.ARTIST,
                    nullArtworkWidget: Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Iconsax.user,
                        size: 30,
                        color: isDarkMode
                            ? AppTheme.playerControlsDark
                            : AppTheme.playerControlsLight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.artist,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${artist.numberOfTracks} songs',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDarkMode
                    ? AppTheme.playerControlsDark
                    : AppTheme.playerControlsLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
