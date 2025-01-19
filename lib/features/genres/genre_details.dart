import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class GenreDetailsView extends StatelessWidget {
  final GenreModel genre;

  const GenreDetailsView({
    super.key,
    required this.genre,
  });

  @override
  Widget build(BuildContext context) {
    final genreController = Get.find<GenreController>();
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
                  genre.genre,
                  style: AppTheme.headlineLarge.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                background: QueryArtworkWidget(
                  id: genre.id,
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
                              '${genre.numOfSongs} songs',
                              style: AppTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${genre.numOfSongs} albums',
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              genreController.playGenreSongs(genre.id),
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
                final genreSongs = genreController.getGenreSongs(genre.id);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: genreSongs.length,
                  itemBuilder: (context, index) {
                    final song = genreSongs[index];

                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
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
                        // Update current playlist to genre songs and play selected song
                        playerController.currentPlaylist.value = genreSongs;
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
