import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/genres/controller/genres_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class GenreDetailsView extends StatefulWidget {
  final GenreModel genre;

  const GenreDetailsView({
    super.key,
    required this.genre,
  });

  @override
  State<GenreDetailsView> createState() => _GenreDetailsViewState();
}

class _GenreDetailsViewState extends State<GenreDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final GenreController _genreController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  final _scrollController = ScrollController();
  final double _itemExtent = 80.0;
  late List<SongModel> _genreSongs;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _genreController = Get.find<GenreController>();
    _playerController = Get.find<PlayerController>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      await _genreController.ensureSongsForGenreLoaded(widget.genre.id);
      _genreSongs = _genreController.getGenreSongs(widget.genre.id);
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
          widget.genre.genre,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: QueryArtworkWidget(
          id: widget.genre.id,
          type: ArtworkType.ARTIST,
          nullArtworkWidget: Container(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            child: const Icon(Iconsax.user, size: 100, color: Colors.grey),
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
                      Text(
                        '${widget.genre.numOfSongs} songs',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.genre.numOfSongs} albums',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PlayAllButton(
                  genre: widget.genre,
                  genreController: _genreController,
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
          song: _genreSongs[index],
          index: index,
          playerController: _playerController,
          genreController: _genreController,
          genreId: widget.genre.id,
        ),
        childCount: _genreSongs.length,
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
  final GenreController genreController;
  final int genreId;

  const _SongListItem({
    required this.song,
    required this.index,
    required this.playerController,
    required this.genreController,
    required this.genreId,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            playerController.currentPlaylist.value =
                genreController.getGenreSongs(genreId);
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
      nullArtworkWidget:
          const Icon(Iconsax.music, size: 50, color: Colors.grey),
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
  final GenreModel genre;
  final GenreController genreController;
  final bool isDarkMode;

  const _PlayAllButton({
    required this.genre,
    required this.genreController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => genreController.playGenreSongs(genre.id),
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
