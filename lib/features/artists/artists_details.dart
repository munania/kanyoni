import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class ArtistsDetailsView extends StatelessWidget {
  final ArtistModel artist;

  const ArtistsDetailsView({
    super.key,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final artistController = Get.find<ArtistController>();
    final playerController = Get.find<PlayerController>();
    final panelController = PanelController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: playerController,
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          playerController: playerController,
          isDarkMode: isDarkMode,
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  artist.artist,
                  style: AppTheme.headlineLarge.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                background: QueryArtworkWidget(
                  id: artist.id,
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
              child: Padding(
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
                              '${artist.numberOfTracks} songs',
                              style: AppTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${artist.numberOfAlbums} albums',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              artistController.playArtistSongs(artist.id),
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
            SliverToBoxAdapter(
              child: Obx(() {
                final artistSongs = artistController.getArtistSongs(artist.id);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: artistSongs.length,
                  itemBuilder: (context, index) {
                    final song = artistSongs[index];

                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: song.albumId!,
                        type: ArtworkType.ALBUM,
                        nullArtworkWidget: CircleAvatar(
                          backgroundColor:
                              isDarkMode ? Colors.grey[800] : Colors.grey[300],
                          child: Text(
                            '${index + 1}',
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: AppTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.album ?? 'Unknown Album',
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          playerController.favoriteSongs.contains(song.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              playerController.favoriteSongs.contains(song.id)
                                  ? AppTheme.playerControlsDark
                                  : null,
                        ),
                        onPressed: () =>
                            playerController.toggleFavorite(song.id),
                      ),
                      onTap: () {
                        // Update current playlist to artist songs and play selected song
                        playerController.currentPlaylist.value = artistSongs;
                        playerController.playSong(index);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
