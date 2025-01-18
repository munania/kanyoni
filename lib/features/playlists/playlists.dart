import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/playlists/playlists_details.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../controllers/music_player_controller.dart';
import '../../utils/theme/theme.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
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
          physics: BouncingScrollPhysics(),
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
    MusicPlayerController controller,
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
                controller.refreshPlaylists();
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
    MusicPlayerController controller,
    PlaylistModel playlist,
  ) {
    final nameController = TextEditingController(text: playlist.playlist);

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
                controller.renamePlaylist(playlist.id, nameController.text);
                controller.refreshPlaylists();
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
    MusicPlayerController controller,
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
              controller.refreshPlaylists();
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

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final bool isDarkMode;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.isDarkMode,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                ),
                child: Icon(
                  Iconsax.music_playlist,
                  size: 30,
                  color: isDarkMode
                      ? AppTheme.playerControlsDark
                      : AppTheme.playerControlsLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.playlist,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.numOfSongs} songs',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit_2),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'rename':
                      onRename();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
