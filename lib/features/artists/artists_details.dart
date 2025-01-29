import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/artists/controller/artists_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

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
    // Load songs in background
    await Future.microtask(() {
      _artistSongs = _artistController.getArtistSongs(widget.artist.id);
    });
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
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          playerController: _playerController,
          isDarkMode: isDarkMode,
        ),
        body: CustomScrollView(
          controller: _scrollController,
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
          widget.artist.artist,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: QueryArtworkWidget(
          id: widget.artist.id,
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
    return ListTile(
      leading: QueryArtworkWidget(
        id: song.albumId!,
        type: ArtworkType.ALBUM,
        nullArtworkWidget: Icon(
          Iconsax.music,
          size: 50,
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
          playerController.favoriteSongs.contains(song.id)
              ? Icons.favorite
              : Icons.favorite_border,
          color: playerController.favoriteSongs.contains(song.id)
              ? AppTheme.playerControlsDark
              : null,
        ),
        onPressed: () => playerController.toggleFavorite(song.id),
      ),
      onTap: () {
        playerController.currentPlaylist.value = artistSongs;
        playerController.playSong(index);
      },
    );
  }
}
