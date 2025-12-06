import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_panel.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:kanyoni/features/playlists/playlist_song_card.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
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
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                    ),
                  )
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
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Iconsax.add_square,
              size: 20,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => _showAddToPlaylistDialog(),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: Text(
          widget.playlist.playlist.replaceAll(' [kanyoni]', ''),
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
              id: widget.playlist.id,
              type: ArtworkType.ARTIST, // Kept as per original
              quality: 100,
              size: 1000,
              artworkQuality: FilterQuality.high,
              nullArtworkWidget: Container(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                child: const Icon(
                  Iconsax.music_playlist,
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
            if (kDebugMode) {
              print('Building song card for index $index');
              print('Playlist songs: ${playlistSongs.length}');
            }
            final song = playlistSongs[index];
            return PlaylistSongCard(
              key: ValueKey(song.id),
              song: song,
              isDarkMode: isDarkMode,
              onPlay: () {
                _playerController.currentPlaylist.value = playlistSongs;
                _playerController.playSong(song);
              },
              onRemove: () {
                _playlistController.removeFromPlaylist(
                  widget.playlist.id,
                  song.id,
                );
              },
            );
          },
          childCount: playlistSongs.length,
        ),
      );
    });
  }

  void _showAddToPlaylistDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistDialogContent(
        playerController: _playerController,
        playlistController: _playlistController,
        playlistId: widget.playlist.id,
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

class _AddToPlaylistDialogContentState extends State<AddToPlaylistDialogContent>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<SongModel> _filteredSongs = [];
  List<SongModel> _availableSongs = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSongs();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterSongs();
      });
    });
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);

    // Get blacklisted folders
    final blacklistedFolders = await getBlacklistedFolders();

    // Filter out songs from blacklisted folders
    _availableSongs = widget.playerController.songs.where((song) {
      final isInBlacklistedFolder = blacklistedFolders.any(
        (folder) => song.data.startsWith(folder),
      );
      return !isInBlacklistedFolder;
    }).toList();

    _filteredSongs = _availableSongs;
    setState(() => _isLoading = false);
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterSongs() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSongs = _availableSongs;
      });
    } else {
      setState(() {
        _filteredSongs = _availableSongs
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Songs',
                  style: AppTheme.headlineMedium.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search songs...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Theme.of(context).primaryColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Song List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSongs.isEmpty
                    ? _buildEmptyState(isDarkMode)
                    : _buildSongList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return FadeTransition(
      opacity: _animationController,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_playlist.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty ? 'No songs available' : 'No songs found',
              style: AppTheme.headlineMedium.copyWith(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchQuery.isEmpty
                    ? 'All songs are either in this playlist or in blacklisted folders'
                    : 'Try searching with different keywords',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(bool isDarkMode) {
    return Obx(() {
      final playlistSongs =
          widget.playlistController.getPlaylistSongs(widget.playlistId);

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredSongs.length,
        itemBuilder: (context, index) {
          final song = _filteredSongs[index];
          final isInPlaylist = playlistSongs.any((s) =>
              s.title == song.title &&
              s.artist == song.artist &&
              s.duration == song.duration &&
              s.data == song.data);

          return FadeTransition(
            opacity: _animationController,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index / _filteredSongs.length).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOut,
                ),
              )),
              child: _ModernSongCard(
                song: song,
                isInPlaylist: isInPlaylist,
                isDarkMode: isDarkMode,
                onToggle: (value) async {
                  if (value) {
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
              ),
            ),
          );
        },
      );
    });
  }
}

class _ModernSongCard extends StatelessWidget {
  final SongModel song;
  final bool isInPlaylist;
  final bool isDarkMode;
  final Function(bool) onToggle;

  const _ModernSongCard({
    required this.song,
    required this.isInPlaylist,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onToggle(!isInPlaylist),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Album Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    keepOldArtwork: true,
                    size: 50,
                    quality: 100,
                    artworkQuality: FilterQuality.high,
                    nullArtworkWidget: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.music,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkmark Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isInPlaylist
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isInPlaylist
                          ? Theme.of(context).primaryColor
                          : (isDarkMode
                              ? Colors.grey[600]!
                              : Colors.grey[400]!),
                      width: 2,
                    ),
                  ),
                  child: isInPlaylist
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
