import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';

import 'album_card.dart';
import 'albums_details.dart';

class AlbumsView extends StatelessWidget {
  const AlbumsView({super.key});

  @override
  Widget build(BuildContext context) {
    final albumController = Get.find<AlbumController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return GridView.builder(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: albumController.albums.length,
        itemBuilder: (context, index) {
          final album = albumController.albums[index];
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
