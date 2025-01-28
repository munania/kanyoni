import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../controllers/player_controller.dart';
import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class FolderDetailsView extends StatefulWidget {
  final String folderPath;

  const FolderDetailsView({
    super.key,
    required this.folderPath,
  });

  @override
  State<FolderDetailsView> createState() => _FolderDetailsViewState();
}

class _FolderDetailsViewState extends State<FolderDetailsView> {
  @override
  Widget build(BuildContext context) {
    final folderController = Get.find<FolderController>();
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
                  path.basename(widget.folderPath),
                  style: AppTheme.headlineLarge.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                background: Container(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.folder,
                    size: 100,
                    color: isDarkMode
                        ? AppTheme.playerControlsDark
                        : AppTheme.playerControlsLight,
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
                            Obx(() {
                              final songCount = folderController
                                  .getSongCount(widget.folderPath);
                              return Text(
                                '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                                style: AppTheme.headlineMedium,
                              );
                            }),
                            const SizedBox(height: 8),
                            Text(
                              widget.folderPath,
                              style: AppTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final songs = folderController
                                .getFolderSongs(widget.folderPath);
                            if (songs.isNotEmpty) {
                              playerController.currentPlaylist.value = songs;
                              playerController.playSong(0);
                            }
                          },
                          icon: Icon(
                            Icons.play_arrow,
                            color: isDarkMode
                                ? AppTheme.nowPlayingDark
                                : AppTheme.nowPlayingLight,
                          ),
                          label: Text(
                            'Play All',
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppTheme.nowPlayingDark
                                  : AppTheme.nowPlayingLight,
                            ),
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
                final folderSongs =
                    folderController.getFolderSongs(widget.folderPath);

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: folderSongs.length,
                  itemBuilder: (context, index) {
                    final song = folderSongs[index];

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
                        playerController.currentPlaylist.value = folderSongs;
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
