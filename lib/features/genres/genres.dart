import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';
import 'genre_details.dart';

class GenreView extends StatelessWidget {
  const GenreView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.genres.length,
        itemBuilder: (context, index) {
          final genre = controller.genres[index];
          return GenreCard(
            genre: genre,
            isDarkMode: isDarkMode,
            onTap: () => Get.to(() => GenreDetailsView(genre: genre)),
          );
        },
      );
    });
  }
}

class GenreCard extends StatelessWidget {
  final GenreModel genre;
  final bool isDarkMode;
  final VoidCallback onTap;

  const GenreCard({
    super.key,
    required this.genre,
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
                    id: genre.id,
                    type: ArtworkType.GENRE,
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
                      genre.genre,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${genre.numOfSongs} songs',
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
