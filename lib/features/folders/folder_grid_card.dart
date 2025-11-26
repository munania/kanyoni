import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:path/path.dart' as path;

class FolderGridCard extends StatelessWidget {
  final String folderPath;
  final int songCount;
  final VoidCallback onTap;

  const FolderGridCard({
    super.key,
    required this.folderPath,
    required this.songCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final folderName = path.basename(folderPath);

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
            // Folder Icon
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).highlightColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.cornerRadius),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.folder_25,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            // Folder Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folderName,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$songCount ${songCount == 1 ? 'song' : 'songs'}',
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
