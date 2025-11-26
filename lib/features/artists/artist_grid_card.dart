import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../utils/theme/theme.dart';

class ArtistGridCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback onTap;

  const ArtistGridCard({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artist Artwork
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.cornerRadius),
                ),
                child: QueryArtworkWidget(
                  id: artist.id,
                  type: ArtworkType.ARTIST,
                  quality: 100,
                  size: 500,
                  artworkQuality: FilterQuality.high,
                  nullArtworkWidget: Container(
                    color:
                        Theme.of(context).highlightColor.withValues(alpha: 0.1),
                    child: Icon(
                      Iconsax.microphone,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            // Artist Info
            Padding(
              padding: const EdgeInsets.all(12),
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
                    '${artist.numberOfTracks} ${artist.numberOfTracks == 1 ? 'song' : 'songs'}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
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
