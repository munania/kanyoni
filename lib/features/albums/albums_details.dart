import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/albums/controller/album_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../utils/theme/theme.dart';

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
    print('Loaded songs: ${_albumSongs.length}');
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
          isDarkMode: isDarkMode,
        ),
        collapsed: CollapsedPanel(
          panelController: _panelController,
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
          widget.album.album,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: QueryArtworkWidget(
          id: widget.album.id,
          type: ArtworkType.ALBUM,
          nullArtworkWidget: Container(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            child: Icon(
              Iconsax.music_square,
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

    return ListTile(
      leading: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(
          size: 50,
          Iconsax.music,
          color: Colors.grey,
        ),
      ),
      title: Text(
        song.title,
        style: AppTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
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
        playerController.currentPlaylist.value = albumSongs;
        playerController.playSong(index);
      },
    );
  }
}
