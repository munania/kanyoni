import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
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

class _FolderDetailsViewState extends State<FolderDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final FolderController _folderController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  final _scrollController = ScrollController();
  final double _itemExtent = 80.0;
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
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          panelController: _panelController,
          playerController: _playerController,
          isDarkMode: isDarkMode,
        ),
        body: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(isDarkMode),
            _buildHeaderSection(isDarkMode),
            _buildSongList(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
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
          color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          child: const Icon(Iconsax.folder_25, size: 100),
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

  Widget _buildSongList() {
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

  const _SongListItem({
    required this.song,
    required this.index,
    required this.playerController,
    required this.folderPath,
  });

  @override
  Widget build(BuildContext context) {
    FolderController folderController = Get.find<FolderController>();
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            playerController.currentPlaylist.value =
                folderController.getFolderSongs(folderPath);
            playerController.playSong(index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _ArtworkWidget(song: song),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTheme.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.album ?? 'Unknown Album',
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _FavoriteButton(song: song, playerController: playerController),
              ],
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
          color: isFavorite ? AppTheme.playerControlsDark : null,
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
        color: isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight,
      ),
      label: Text(
        'Play All',
        style: TextStyle(
          color:
              isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? AppTheme.playerControlsDark
            : AppTheme.playerControlsLight,
      ),
    );
  }
}
