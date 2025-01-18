import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/playlists/playlist_song_card.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../controllers/music_player_controller.dart';
import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class PlaylistDetailsView extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistDetailsView({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicPlayerController>();
    final panelController = PanelController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    controller.songCount.value = playlist.numOfSongs;

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          controller: controller,
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          controller: controller,
          isDarkMode: isDarkMode,
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              actions: [
                IconButton(
                  icon: const Icon(
                    Iconsax.add_square,
                    size: 30,
                  ),
                  onPressed: () =>
                      _showAddToPlaylistDialog(context, controller),
                ),
              ],
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  playlist.playlist,
                  style: AppTheme.headlineLarge.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                background: QueryArtworkWidget(
                  id: playlist.id,
                  type: ArtworkType.ARTIST,
                  nullArtworkWidget: Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    child: Icon(
                      Iconsax.user,
                      size: 100,
                      color: isDarkMode
                          ? AppTheme.playerControlsDark
                          : AppTheme.playerControlsLight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(
                () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.songCount.value} songs',
                                style: AppTheme.headlineMedium,
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                controller.playPlaylist(playlist.id),
                            icon: Icon(Icons.play_arrow,
                                color: isDarkMode
                                    ? AppTheme.nowPlayingDark
                                    : AppTheme.nowPlayingLight),
                            label: Text(
                              'Play All',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? AppTheme.nowPlayingDark
                                      : AppTheme.nowPlayingLight),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? AppTheme.playerControlsDark
                                  : AppTheme.playerControlsLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (controller.songs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final playlistSongs = controller.getPlaylistSongs(playlist.id);

                if (playlistSongs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.music,
                          size: 72,
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Songs',
                          style: AppTheme.headlineMedium.copyWith(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add songs to this playlist',
                          style: AppTheme.bodyMedium.copyWith(
                            color: isDarkMode ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: playlistSongs.length,
                  itemBuilder: (context, index) {
                    final playlistSong = playlistSongs[index];
                    // Find the matching song from the main songs list
                    final mainSong = controller.songs.firstWhereOrNull((s) =>
                        s.title == playlistSong.title &&
                        s.artist == playlistSong.artist);

                    // Use the main song if found, otherwise use playlist song
                    final songToUse = mainSong ?? playlistSong;

                    return PlaylistSongCard(
                      key: ValueKey(songToUse.id),
                      song: songToUse,
                      isDarkMode: isDarkMode,
                      onPlay: () {
                        controller.currentPlaylist.value = playlistSongs;
                        controller.playSong(songToUse);
                      },
                      onRemove: () {
                        controller.removeFromPlaylist(
                            playlist.id, playlistSong.id);
                        controller.refreshPlaylists();
                      },
                    );
                  },
                );
              }),
            )
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    MusicPlayerController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Obx(() {
            final songs = controller.songs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Obx(() {
                  final isInPlaylist =
                      controller.isInPlaylist(playlist.id, song.title);

                  return CheckboxListTile(
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: isInPlaylist,
                    onChanged: (value) async {
                      if (value ?? false) {
                        final success = await controller.addToPlaylist(
                            playlist.id, song.id);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add song to playlist'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        await controller.removeFromPlaylist(
                            playlist.id, song.id);
                      }
                    },
                  );
                });
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
