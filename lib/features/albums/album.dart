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

class _AlbumsViewState extends State<AlbumsView>
    with AutomaticKeepAliveClientMixin {
  late AlbumController albumController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    albumController = Get.find<AlbumController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      return Scaffold(
        body: GridView.builder(
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
              onTap: () => Get.to(() => AlbumDetailsView(album: album)),
            );
          },
        ),
      );
    });
  }
}
