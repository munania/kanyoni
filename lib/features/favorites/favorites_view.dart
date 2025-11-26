import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final PlayerController playerController = Get.find();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        // Get current song for background artwork
        final currentSongIndex = playerController.currentSongIndex.value;
        final hasCurrentSong = currentSongIndex >= 0 &&
            currentSongIndex < playerController.currentPlaylist.length;
        final currentSong = hasCurrentSong
            ? playerController.currentPlaylist[currentSongIndex]
            : null;

        return Stack(
          children: [
            // Background Artwork with Blur
            RepaintBoundary(
              child: Stack(
                children: [
                  if (currentSong != null)
                    Positioned.fill(
                      child: QueryArtworkWidget(
                        id: currentSong.id,
                        type: ArtworkType.AUDIO,
                        quality: 100,
                        size: 1000,
                        artworkQuality: FilterQuality.high,
                        nullArtworkWidget: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ThemedArtworkPlaceholder(
                        iconSize: 120,
                      ),
                    ),
                  // Blur Effect
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(
                                alpha: isDarkMode ? 0.7 : 0.85,
                              ),
                          child: Container(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            if (playerController.favoriteSongs.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.heart,
                      size: 80,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Favorites Yet',
                      style: AppTheme.headlineMedium.copyWith(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Songs you mark as favorites will appear here',
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: playerController.favoriteSongs.length,
                itemBuilder: (context, index) {
                  final songId = playerController.favoriteSongs[index];
                  final SongModel? song = playerController.songs
                      .firstWhereOrNull((s) => s.id == songId);

                  if (song == null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.02),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.music_circle,
                                size: 56,
                                color: isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Song Not Found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This song might have been removed',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Dismissible(
                    key: Key(song.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Iconsax.heart_slash,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) {
                      playerController.toggleFavorite(song.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.02),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              final favoriteSongsList = playerController
                                  .favoriteSongs
                                  .map((id) => playerController.songs
                                      .firstWhereOrNull((s) => s.id == id))
                                  .whereType<SongModel>()
                                  .toList();
                              playerController.currentPlaylist.value =
                                  favoriteSongsList;
                              playerController.playSong(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: QueryArtworkWidget(
                                      id: song.id,
                                      type: ArtworkType.AUDIO,
                                      nullArtworkWidget: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Iconsax.music_circle,
                                          size: 28,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      artworkWidth: 56,
                                      artworkHeight: 56,
                                      artworkFit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          song.artist ?? 'Unknown Artist',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Iconsax.heart5,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    onPressed: () {
                                      playerController.toggleFavorite(song.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
          ],
        );
      }),
    );
  }
}
