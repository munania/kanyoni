import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/playlists/playlist_card.dart';
import 'package:kanyoni/features/playlists/playlists_details.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../utils/theme/theme.dart';
import 'controller/playlists_controller.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlaylistController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(
              Iconsax.add_square,
              size: 30,
            ),
            onPressed: () => _showCreatePlaylistDialog(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.playlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.music_playlist,
                  size: 72,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Playlists',
                  style: AppTheme.headlineMedium.copyWith(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a playlist to organize your songs',
                  style: AppTheme.bodyMedium.copyWith(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: controller.playlists.length,
          itemBuilder: (context, index) {
            final playlist = controller.playlists[index];
            return PlaylistCard(
              playlist: playlist,
              isDarkMode: isDarkMode,
              onTap: () =>
                  Get.to(() => PlaylistDetailsView(playlist: playlist)),
              onRename: () => _showRenamePlaylistDialog(
                context,
                controller,
                playlist,
              ),
              onDelete: () => _showDeletePlaylistDialog(
                context,
                controller,
                playlist,
              ),
            );
          },
        );
      }),
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    PlaylistController controller,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                controller.createPlaylist(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(
    BuildContext context,
    PlaylistController controller,
    PlaylistModel playlist,
  ) {
    final nameController = TextEditingController(
        text: playlist.playlist.replaceAll(' [kanyoni]', ''));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                controller.renameMyPlaylist(playlist.id, nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(
    BuildContext context,
    PlaylistController controller,
    PlaylistModel playlist,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content:
            Text('Are you sure you want to delete "${playlist.playlist}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
