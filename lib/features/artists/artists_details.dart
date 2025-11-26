import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_panel.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ArtistsDetailsView extends StatefulWidget {
  final ArtistModel artist;

  const ArtistsDetailsView({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistsDetailsView> createState() => _ArtistsDetailsViewState();
}

class _ArtistsDetailsViewState extends State<ArtistsDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final ArtistController _artistController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  late List<SongModel> _artistSongs;
  final _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _artistController = Get.find<ArtistController>();
    _playerController = Get.find<PlayerController>();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    await _artistController.ensureSongsForArtistLoaded(widget.artist.id);
    _artistSongs = _artistController.getArtistSongs(widget.artist.id);
    setState(() => _isLoading = false);
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
          widget.artist.artist,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: QueryArtworkWidget(
          id: widget.artist.id,
          type: ArtworkType.ARTIST,
          quality: 100,
          size: 1000,
          artworkQuality: FilterQuality.high,
          nullArtworkWidget: Container(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            child: Icon(
              Iconsax.user,
              size: 100,
              color: Colors.grey,
            ),
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
                        '${widget.artist.numberOfTracks} songs',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.artist.numberOfAlbums} albums',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () =>
                      _artistController.playArtistSongs(widget.artist.id),
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
          song: _artistSongs[index],
          index: index,
          isDarkMode: isDarkMode,
          playerController: _playerController,
          artistSongs: _artistSongs,
        ),
        childCount: _artistSongs.length,
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
  final List<SongModel> artistSongs;

  const _SongListItem({
    required this.song,
    required this.index,
    required this.isDarkMode,
    required this.playerController,
    required this.artistSongs,
  });

  @override
  Widget build(BuildContext context) {
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
              id: song.albumId!,
              type: ArtworkType.ALBUM,
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
            song.album ?? 'Unknown Album',
            style: AppTheme.bodyMedium.copyWith(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              playerController.favoriteSongs.contains(song.id)
                  ? Iconsax.heart5
                  : Iconsax.heart,
              color: playerController.favoriteSongs.contains(song.id)
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            onPressed: () => playerController.toggleFavorite(song.id),
          ),
          onTap: () {
            playerController.currentPlaylist.value = artistSongs;
            playerController.playSong(index);
          },
        ),
      ),
    );
  }
}
