import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import '../../utils/theme/theme.dart';
import '../now_playing/now_playing_widgets.dart';

class TracksView extends StatelessWidget {
  const TracksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const TracksList(),
    );
  }
}

class TracksList extends StatefulWidget {
  const TracksList({super.key});

  @override
  State<TracksList> createState() => _TracksListState();
}

class _TracksListState extends State<TracksList>
    with AutomaticKeepAliveClientMixin {
  late final PlayerController _playerController;
  final double _itemExtent =
      88.0; // 80px height + 8px margins (4px top + 4px bottom)

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerController = Get.find<PlayerController>();
    // Fetch songs when view is initialized
    _playerController.fetchAllSongs();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final songCount = _playerController.songs.length.toString();
      // Get current song for background artwork
      final currentSongIndex = _playerController.currentSongIndex.value;
      final hasCurrentSong = currentSongIndex >= 0 &&
          currentSongIndex < _playerController.currentPlaylist.length;
      final currentSong = hasCurrentSong
          ? _playerController.currentPlaylist[currentSongIndex]
          : null;

      return Stack(
        children: [
          // Background Artwork with Blur
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
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(
                      alpha: isDarkMode ? 0.7 : 0.85,
                    ),
                child: Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),

          // Content
          RefreshIndicator(
            onRefresh: () async {
              await _playerController.refreshSongs();
            },
            child: CustomScrollView(
              cacheExtent: 1000,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Modern header with song count and sort
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Song count with icon
                        Row(
                          children: [
                            Icon(
                              Iconsax.music_library_2,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$songCount Songs",
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),

                        // Modern sort dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<SongSortType>(
                            value: _playerController.currentSortType.value,
                            dropdownColor:
                                isDarkMode ? Colors.grey[850] : Colors.white,
                            style: AppTheme.bodyMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            underline: const SizedBox(),
                            icon: Icon(
                              Iconsax.arrow_down_1,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            menuMaxHeight: 300,
                            itemHeight: 48,
                            items: [
                              DropdownMenuItem(
                                value: SongSortType.TITLE,
                                child: Row(
                                  children: [
                                    Icon(Iconsax.text,
                                        size: 18,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    const Text("Name"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongSortType.ARTIST,
                                child: Row(
                                  children: [
                                    Icon(Iconsax.microphone,
                                        size: 18,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    const Text("Artist"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongSortType.ALBUM,
                                child: Row(
                                  children: [
                                    Icon(Iconsax.music_dashboard,
                                        size: 18,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    const Text("Album"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongSortType.DATE_ADDED,
                                child: Row(
                                  children: [
                                    Icon(Iconsax.calendar,
                                        size: 18,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    const Text("Date Added"),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: SongSortType.DURATION,
                                child: Row(
                                  children: [
                                    Icon(Iconsax.clock,
                                        size: 18,
                                        color: Theme.of(context).primaryColor),
                                    const SizedBox(width: 8),
                                    const Text("Duration"),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                await _playerController.refreshSongs(
                                    sortType: value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Existing song list
                SliverFixedExtentList(
                  itemExtent: _itemExtent,
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = _playerController.songs[index];
                      return _TrackListItem(
                        song: song,
                        index: index,
                        playerController: _playerController,
                      );
                    },
                    childCount: _playerController.songs.length,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _TrackListItem extends StatelessWidget {
  final SongModel song;
  final int index;
  final PlayerController playerController;

  const _TrackListItem({
    required this.song,
    required this.index,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              playerController.currentPlaylist.value = playerController.songs;
              playerController.playSong(index);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Album artwork with rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _ArtworkWidget(song: song, isDarkMode: isDarkMode),
                  ),
                  const SizedBox(width: 12),
                  // Song info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ?? 'Unknown Artist',
                          style: AppTheme.bodyMedium.copyWith(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Play icon hint
                  Icon(
                    Iconsax.play_circle,
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final SongModel song;
  final bool isDarkMode;

  const _ArtworkWidget({required this.song, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        keepOldArtwork: true,
        size: 50,
        quality: 100,
        artworkQuality: FilterQuality.high,
        nullArtworkWidget: const ThemedArtworkPlaceholder(
          iconSize: 24,
          icon: Iconsax.music,
        ),
      ),
    );
  }
}
