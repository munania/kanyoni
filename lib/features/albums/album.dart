import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';

import 'album_card.dart';
import 'albums_details.dart';

class AlbumsView extends StatefulWidget {
  const AlbumsView({super.key});

  @override
  State<AlbumsView> createState() => _AlbumsViewState();
}

class _AlbumsViewState extends State<AlbumsView> {
  late ScrollController _scrollController;
  late AlbumController albumController;

  @override
  void initState() {
    super.initState();
    albumController = Get.find<AlbumController>();
    _scrollController = ScrollController(
      initialScrollOffset: albumController.shouldRestoreScrollPosition()
          ? albumController.listScrollOffset.value
          : 0.0,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    albumController.updateListScrollPosition(_scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return GridView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
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
