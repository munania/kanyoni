import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path/path.dart' as path;

import 'controllers/folder_controller.dart';
import 'folders_details.dart';

class FoldersView extends StatefulWidget {
  const FoldersView({super.key});

  @override
  State<FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<FoldersView>
    with AutomaticKeepAliveClientMixin {
  late final FolderController folderController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    folderController = Get.find<FolderController>();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                color: Colors.grey,
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
                color: Colors.grey,
                size: 20,
              ),
            );
          },
        ));
  }
}
