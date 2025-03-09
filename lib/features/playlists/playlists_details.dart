import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:kanyoni/features/playlists/playlist_song_card.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../now_playing.dart';
import '../../utils/theme/theme.dart';

class PlaylistDetailsView extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistDetailsView({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailsView> createState() => _PlaylistDetailsViewState();
}

class _PlaylistDetailsViewState extends State<PlaylistDetailsView>
    with AutomaticKeepAliveClientMixin {
  late final PlaylistController _playlistController;
  late final PlayerController _playerController;
  final _panelController = PanelController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playlistController = Get.find<PlaylistController>();
    _playerController = Get.find<PlayerController>();
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
          slivers: [
            _buildAppBar(isDarkMode),
            _buildHeaderSection(isDarkMode),
            _buildSongList(isDarkMode),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
              ),
            )
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDarkMode) {
    return SliverAppBar(
      actions: [
        IconButton(
          icon: const Icon(Iconsax.add_square, size: 30),
          onPressed: () => _showAddToPlaylistDialog(),
        ),
      ],
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.playlist.playlist.replaceAll(' [kanyoni]', ''),
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyLarge.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        background: QueryArtworkWidget(
          id: widget.playlist.id,
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
                  child: Obx(() {
                    final songCount = _playlistController
                        .getPlaylistSongs(widget.playlist.id)
                        .length;
                    return Text(
                      '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                      style: AppTheme.headlineMedium,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _playlistController.playPlaylist(
                    widget.playlist.id,
                    startIndex: 0,
                  ),
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
    return Obx(() {
      final playlistSongs =
          _playlistController.getPlaylistSongs(widget.playlist.id);

      if (playlistSongs.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.music,
                  size: 72,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Songs',
                  style: AppTheme.headlineMedium.copyWith(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add songs to this playlist',
                  style: AppTheme.bodyMedium.copyWith(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = playlistSongs[index];
            return PlaylistSongCard(
              key: ValueKey(song.id),
              song: song,
              isDarkMode: isDarkMode,
              onPlay: () {
                _playerController.currentPlaylist.value = playlistSongs;
                _playerController.playSong(song);
              },
              onRemove: () => _playlistController.removeFromPlaylist(
                widget.playlist.id,
                song.id,
              ),
            );
          },
          childCount: playlistSongs.length,
        ),
      );
    });
  }

  void _showAddToPlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Obx(() {
            final songs = _playerController.songs;
            final playlistSongs =
                _playlistController.getPlaylistSongs(widget.playlist.id);

            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isInPlaylist = playlistSongs.any((s) =>
                    s.title == song.title &&
                    s.artist == song.artist &&
                    s.duration == song.duration &&
                    s.data == song.data);

                return CheckboxListTile(
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: isInPlaylist,
                  onChanged: (value) async {
                    if (value ?? false) {
                      await _playlistController.addToPlaylist(
                        widget.playlist.id,
                        song.id,
                      );
                    } else {
                      await _playlistController.removeFromPlaylist(
                        widget.playlist.id,
                        song.id,
                      );
                    }
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
