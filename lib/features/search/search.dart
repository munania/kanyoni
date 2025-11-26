import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_panel.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final PlayerController playerController = Get.find<PlayerController>();
  final PanelController panelController = PanelController();
  final TextEditingController _searchController = TextEditingController();
  final RxList<SongModel> _filteredSongs = <SongModel>[].obs;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    playerController.currentPlaylist.value = playerController.songs;
    super.dispose();
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      _filteredSongs.value = playerController.songs;
    } else {
      _filteredSongs.value = playerController.songs
          .where((song) =>
              song.title.toLowerCase().contains(query.toLowerCase()) ||
              (song.artist?.toLowerCase() ?? '').contains(query.toLowerCase()))
          .toList();
    }
  }

  void _playFromSearch(SongModel song) {
    //update the current playlist to the filtered songs
    playerController.currentPlaylist.value = _filteredSongs;

    //Find the index of the song in the filtered list
    final index = _filteredSongs.indexWhere((s) => s.id == song.id);

    // Play the selected song
    if (index != -1) {
      playerController.playSong(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Important: only on the root Scaffold
      body: SlidingUpPanel(
        controller: panelController,
        minHeight: 80,
        maxHeight: MediaQuery.of(context).size.height,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.cornerRadius),
        ),
        panel: NowPlayingPanel(
          playerController: playerController,
        ),
        collapsed: CollapsedPanel(
          panelController: panelController,
          playerController: playerController,
        ),
        body: Obx(() {
          // Get current song for background artwork
          final currentSongIndex = playerController.currentSongIndex.value;
          final hasCurrentSong = currentSongIndex >= 0 &&
              currentSongIndex < playerController.currentPlaylist.length;
          final currentSong = hasCurrentSong
              ? playerController.currentPlaylist[currentSongIndex]
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
              SafeArea(
                child: Column(
                  children: [
                    // Modern search bar
                    Container(
                      margin: const EdgeInsets.all(16),
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
                        autofocus: true,
                        controller: _searchController,
                        onChanged: (value) {
                          _filterSongs(value);
                          setState(() {}); // Rebuild to show/hide clear button
                        },
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Iconsax.search_normal,
                            color: Theme.of(context).primaryColor,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Iconsax.close_circle),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterSongs('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(
                        () => _filteredSongs.isEmpty
                            ? _buildEmptyState(isDarkMode)
                            : ListView.builder(
                                itemCount: _filteredSongs.length,
                                itemBuilder: (context, index) {
                                  final song = _filteredSongs[index];
                                  return _ModernSearchResultCard(
                                    song: song,
                                    isDarkMode: isDarkMode,
                                    onTap: () => _playFromSearch(song),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_status,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No songs found',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: AppTheme.bodyMedium.copyWith(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSearchResultCard extends StatelessWidget {
  final SongModel song;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ModernSearchResultCard({
    required this.song,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    size: 50,
                    nullArtworkWidget: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .highlightColor
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Iconsax.music,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.play_circle,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
