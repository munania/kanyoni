import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:kanyoni/features/playlists/playlist_song_card.dart';
import 'package:kanyoni/now_playing.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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
    _playlistController.ensureSongsForPlaylistLoaded(widget.playlist.id);
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
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Songs',
                  style: AppTheme.headlineMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add songs to this playlist',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.grey,
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
        content: AddToPlaylistDialogContent(
          playerController: _playerController,
          playlistController: _playlistController,
          playlistId: widget.playlist.id,
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

class AddToPlaylistDialogContent extends StatefulWidget {
  final PlayerController playerController;
  final PlaylistController playlistController;
  final int playlistId;

  const AddToPlaylistDialogContent({
    super.key,
    required this.playerController,
    required this.playlistController,
    required this.playlistId,
  });

  @override
  State<AddToPlaylistDialogContent> createState() =>
      _AddToPlaylistDialogContentState();
}

class _AddToPlaylistDialogContentState
    extends State<AddToPlaylistDialogContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<SongModel> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    // Initialize filtered songs with all songs
    _filteredSongs = widget.playerController.songs;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterSongs();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSongs() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSongs = widget.playerController.songs;
      });
    } else {
      setState(() {
        _filteredSongs = widget.playerController.songs
            .where((song) =>
                song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (song.artist?.toLowerCase() ?? '')
                    .contains(_searchQuery.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final playlistSongs =
                  widget.playlistController.getPlaylistSongs(widget.playlistId);

              return ListView.builder(
                itemCount: _filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = _filteredSongs[index];
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
                        await widget.playlistController.addToPlaylist(
                          widget.playlistId,
                          song.id,
                        );
                      } else {
                        await widget.playlistController.removeFromPlaylist(
                          widget.playlistId,
                          song.id,
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
