import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path/path.dart' as path;

import '../../utils/theme/theme.dart';
import 'controllers/folder_controller.dart';
import 'folders_details.dart';

class FoldersView extends StatelessWidget {
  const FoldersView({super.key});

  @override
  Widget build(BuildContext context) {
    final folderController = Get.find<FolderController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: folderController.folders.length,
          itemBuilder: (context, index) {
            final folder = folderController.folders[index];
            final songCount = folderController.getSongCount(folder);

            return ListTile(
              leading: Icon(
                Iconsax.folder_25,
                color: isDarkMode
                    ? AppTheme.playerControlsDark
                    : AppTheme.playerControlsLight,
                size: 48,
              ),
              title: Text(
                path.basename(folder),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              onTap: () {
                // Navigate to folder details
                Get.to(() => FolderDetailsView(
                      folderPath: folder,
                    ));
              },
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode
                    ? AppTheme.playerControlsDark
                    : AppTheme.playerControlsLight,
                size: 20,
              ),
            );
          },
        ));
  }
}
