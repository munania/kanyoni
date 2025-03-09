import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../utils/theme/theme.dart';

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
          color:
              isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight,
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
                      color: Colors.grey,
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
