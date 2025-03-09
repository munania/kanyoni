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
  late List<SongModel> _folderSongs;
  final _scrollController = ScrollController();
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
      await Future.microtask(() {
        _folderSongs = _folderController.getFolderSongs(widget.folderPath);
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading folder songs: $e");
      }
    } finally {
      setState(() => _isLoading = false);
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
          slivers: [
            _buildAppBar(isDarkMode),
            _buildHeaderSection(isDarkMode),
            _buildSongList(isDarkMode),
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
          semanticsLabel: widget.folderPath,
          style: AppTheme.bodyLarge.copyWith(
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
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_folderSongs.isNotEmpty) {
                      // Use cached list
                      _playerController.currentPlaylist.value = _folderSongs;
                      _playerController.playSong(0);
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
    );
  }

  Widget _buildSongList(bool isDarkMode) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: isDarkMode
                ? AppTheme.playerControlsDark
                : AppTheme.playerControlsLight,
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _SongListItem(
          song: _folderSongs[index],
          index: index,
          isDarkMode: isDarkMode,
          playerController: _playerController,
          folderSongs: _folderSongs,
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
  final bool isDarkMode;
  final PlayerController playerController;
  final List<SongModel> folderSongs;

  const _SongListItem({
    required this.song,
    required this.index,
    required this.isDarkMode,
    required this.playerController,
    required this.folderSongs,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = playerController.favoriteSongs.contains(song.id);

    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(
          size: 50,
          Iconsax.music,
          color: isDarkMode
              ? AppTheme.playerControlsDark
              : AppTheme.playerControlsLight,
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
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppTheme.playerControlsDark : null,
        ),
        onPressed: () => playerController.toggleFavorite(song.id),
      ),
      onTap: () {
        playerController.currentPlaylist.value = folderSongs;
        playerController.playSong(index);
      },
    );
  }
}
