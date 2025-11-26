import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_panel.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../controllers/player_controller.dart';

class FolderDetailsView extends StatefulWidget {
  final String folderPath;

  const FolderDetailsView({
    super.key,
    required this.folderPath,
  });

  @override
  State<FolderDetailsView> createState() => _FolderDetailsViewState();
}

class _FolderDetailsViewState extends State<FolderDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final FolderController _folderController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  final _scrollController = ScrollController();
  final double _itemExtent = 88.0; // Increased height for padding
  late List<SongModel> _folderSongs;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _folderController = Get.find<FolderController>();
    _playerController = Get.find<PlayerController>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      _folderSongs = _folderController.getFolderSongs(widget.folderPath);
    } catch (e) {
      if (kDebugMode) print("Error loading folder songs: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 70,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: _playerController,
        ),
        collapsed: CollapsedPanel(
          panelController: _panelController,
          playerController: _playerController,
        ),
        body: Obx(() {
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
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(isDarkMode),
                  _buildHeaderSection(isDarkMode),
                  _buildSongList(isDarkMode),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.folderPath,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: Container(
          color: Theme.of(context).highlightColor.withValues(alpha: 0.5),
          child: Icon(
            Iconsax.folder_25,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final songCount =
                            _folderController.getSongCount(widget.folderPath);
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
                ),
                const SizedBox(width: 8),
                _PlayAllButton(
                  folderSongs: _folderSongs,
                  playerController: _playerController,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(bool isDarkMode) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SliverFixedExtentList(
      itemExtent: _itemExtent,
      delegate: SliverChildBuilderDelegate(
        (context, index) => _SongListItem(
          song: _folderSongs[index],
          index: index,
          playerController: _playerController,
          folderPath: widget.folderPath,
          isDarkMode: isDarkMode,
        ),
        childCount: _folderSongs.length,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _SongListItem extends StatelessWidget {
  final SongModel song;
  final int index;
  final PlayerController playerController;
  final String folderPath;
  final bool isDarkMode;

  const _SongListItem({
    required this.song,
    required this.index,
    required this.playerController,
    required this.folderPath,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    FolderController folderController = Get.find<FolderController>();
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
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
                playerController.currentPlaylist.value =
                    folderController.getFolderSongs(folderPath);
                playerController.playSong(index);
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _ArtworkWidget(song: song),
                    ),
                    const SizedBox(width: 16),
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
                            song.album ?? 'Unknown Album',
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
                    _FavoriteButton(
                        song: song, playerController: playerController),
                  ],
                ),
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

  const _ArtworkWidget({required this.song});

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: song.id,
      type: ArtworkType.AUDIO,
      size: 50,
      quality: 100,
      artworkQuality: FilterQuality.high,
      keepOldArtwork: true,
      nullArtworkWidget: const Icon(Iconsax.music, size: 50),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final SongModel song;
  final PlayerController playerController;

  const _FavoriteButton({
    required this.song,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFavorite = playerController.favoriteSongs.contains(song.id);
      return IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          // color: isFavorite ? AppTheme.playerControlsDark : null,
        ),
        onPressed: () => playerController.toggleFavorite(song.id),
      );
    });
  }
}

class _PlayAllButton extends StatelessWidget {
  final List<SongModel> folderSongs;
  final PlayerController playerController;
  final bool isDarkMode;

  const _PlayAllButton({
    required this.folderSongs,
    required this.playerController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: folderSongs.isEmpty
          ? null
          : () {
              playerController.currentPlaylist.value = folderSongs;
              playerController.playSong(0);
            },
      icon: Icon(
        Icons.play_arrow,
        // color: isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight,
      ),
      label: Text(
        'Play All',
        style: TextStyle(
            // color:
            // isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight,
            ),
      ),
      style: ElevatedButton.styleFrom(
          // backgroundColor: isDarkMode
          //     ? AppTheme.playerControlsDark
          //     : AppTheme.playerControlsLight,
          ),
    );
  }
}
