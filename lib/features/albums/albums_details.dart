import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_panel.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class AlbumDetailsView extends StatefulWidget {
  final AlbumModel album;

  const AlbumDetailsView({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailsView> createState() => _AlbumDetailsViewState();
}

class _AlbumDetailsViewState extends State<AlbumDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final AlbumController _albumController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  late List<SongModel> _albumSongs;
  final _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _albumController = Get.find<AlbumController>();
    _playerController = Get.find<PlayerController>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    await _albumController.ensureSongsForAlbumLoaded(widget.album.id);
    _albumSongs = _albumController.getAlbumSongs(widget.album.id).toList();
    if (kDebugMode) {
      print('Loaded songs: ${_albumSongs.length}');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = THelperFunctions.isDarkMode(context);

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
                slivers: [
                  _buildAppBar(isDarkMode),
                  _buildHeaderSection(isDarkMode),
                  _buildSongList(isDarkMode),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 20,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          widget.album.album,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: AppTheme.headlineMedium.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            QueryArtworkWidget(
              id: widget.album.id,
              type: ArtworkType.ALBUM,
              quality: 100,
              size: 1000,
              artworkQuality: FilterQuality.high,
              nullArtworkWidget: Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                child: const Icon(
                  Iconsax.music_square,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.5),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSection(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.artist ?? 'Unknown Artist',
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.album.numOfSongs} songs',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _albumController.playAlbumSongs(widget.album.id),
              icon: Icon(
                Icons.play_arrow,
              ),
              label: Text(
                'Play All',
                style: TextStyle(),
              ),
              style: ElevatedButton.styleFrom(),
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _SongListItem(
          song: _albumSongs[index],
          index: index,
          isDarkMode: isDarkMode,
          playerController: _playerController,
          albumSongs: _albumSongs,
        ),
        childCount: _albumSongs.length,
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
  final List<SongModel> albumSongs;

  const _SongListItem({
    required this.song,
    required this.index,
    required this.isDarkMode,
    required this.playerController,
    required this.albumSongs,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = playerController.favoriteSongs.contains(song.id);

    return Padding(
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
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Iconsax.music,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              artworkWidth: 50,
              artworkHeight: 50,
              artworkFit: BoxFit.cover,
            ),
          ),
          title: Text(
            song.title,
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artist ?? 'Unknown Artist',
            style: AppTheme.bodyMedium.copyWith(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              isFavorite ? Iconsax.heart5 : Iconsax.heart,
              color: isFavorite ? Theme.of(context).primaryColor : null,
            ),
            onPressed: () => playerController.toggleFavorite(song.id),
          ),
          onTap: () {
            playerController.currentPlaylist.value = albumSongs;
            playerController.playSong(index);
          },
        ),
      ),
    );
  }
}
