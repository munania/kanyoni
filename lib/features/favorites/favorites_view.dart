import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart'; // Ensure this is imported

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Obx(() {
        if (playerController.favoriteSongs.isEmpty) {
          return const Center(
            child: Text('No favorite songs yet.'),
          );
        } else {
          return ListView.builder(
            itemCount: playerController.favoriteSongs.length,
            itemBuilder: (context, index) {
              final songId = playerController.favoriteSongs[index];
              final SongModel? song = playerController.songs
                  .firstWhereOrNull((s) => s.id == songId);

              if (song == null) {
                // Optional: Display a placeholder or a message if song details are not found
                return ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text('Song ID: $songId (Details not found)'),
                  subtitle: const Text(
                      'This song might have been removed or is not available.'),
                );
              }

              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: const Icon(Icons.music_note, size: 40),
                  artworkBorder: BorderRadius.circular(6.0),
                  // artworkClipBehavior: Clip.antiAliasWithSaveLayer, // Optional: for smoother edges
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  song.artist ?? "Unknown Artist",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        playerController.playSong(song);
                      },
                    ),
                    IconButton(
                      icon: playerController.favoriteSongs.contains(song.id)
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : const Icon(Icons.favorite_border),
                      onPressed: () {
                        playerController.toggleFavorite(song.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  playerController.playSong(song);
                },
              );
            },
          );
        }
      }),
    );
  }
}
