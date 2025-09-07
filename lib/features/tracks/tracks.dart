import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';

import '../../utils/theme/theme.dart';

class TracksView extends StatelessWidget {
  const TracksView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TracksList();
  }
}

class TracksList extends StatefulWidget {
  const TracksList({super.key});

  @override
  State<TracksList> createState() => _TracksListState();
}

class _TracksListState extends State<TracksList>
    with AutomaticKeepAliveClientMixin {
  late final PlayerController _playerController;
  final double _itemExtent = 80.0; // Fixed height for all items

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerController = Get.find<PlayerController>();
  }

  @override
  Widget build(BuildContext context) {
    final intSongCount = _playerController.songs.length.toString();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    super.build(context);
    return Obx(() => RefreshIndicator(
          onRefresh: () async {
            await _playerController.refreshSongs();
          },
          child: CustomScrollView(
            cacheExtent: 1000,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Add song count as first sliver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Song count (left)
                      Text(
                        "$intSongCount Songs",
                        style: AppTheme.bodyMedium.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),

                      // Filter dropdown (right)
                      DropdownButton<SongSortType>(
                        // value: _playerController.currentSortType.value,
                        dropdownColor: isDarkMode ? Colors.black : Colors.white,
                        style: AppTheme.bodyMedium.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: SongSortType.TITLE,
                            child: Text("Name"),
                          ),
                          DropdownMenuItem(
                            value: SongSortType.ARTIST,
                            child: Text("Artist"),
                          ),
                          DropdownMenuItem(
                            value: SongSortType.ALBUM,
                            child: Text("Album"),
                          ),
                          DropdownMenuItem(
                            value: SongSortType.DATE_ADDED,
                            child: Text("Date Added"),
                          ),
                          DropdownMenuItem(
                            // value: SongSortType.DATE_MODIFIED,
                            child: Text("Date Modified"),
                          ),
                          DropdownMenuItem(
                            value: SongSortType.DURATION,
                            child: Text("Duration"),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            // _playerController.currentSortType.value = value;

                            // Refresh songs using on_audio_query with sorting
                            await _playerController.refreshSongs(
                                // sortType: value,
                                // orderType: OrderType.ASC_OR_SMALLER, // or DESC
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Existing song list
              SliverFixedExtentList(
                itemExtent: _itemExtent,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = _playerController.songs[index];
                    return _TrackListItem(
                      song: song,
                      index: index,
                      playerController: _playerController,
                    );
                  },
                  childCount: _playerController.songs.length,
                ),
              ),
            ],
          ),
        ));
  }
}

class _TrackListItem extends StatelessWidget {
  final SongModel song;
  final int index;
  final PlayerController playerController;

  const _TrackListItem({
    required this.song,
    required this.index,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: SizedBox(
        height: 80, // Match SliverFixedExtentList's itemExtent
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => playerController.playSong(song),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _ArtworkWidget(song: song, isDarkMode: isDarkMode),
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
                          song.artist ?? 'Unknown Artist',
                          style: AppTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtworkWidget extends StatelessWidget {
  final SongModel song;
  final bool isDarkMode;

  const _ArtworkWidget({required this.song, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      id: song.id,
      type: ArtworkType.AUDIO,
      keepOldArtwork: true,
      size: 50,
      quality: 100,
      artworkQuality: FilterQuality.high,
      nullArtworkWidget: const Icon(
        Iconsax.music,
        size: 50,
        color: Colors.grey, // Use constant color for better performance
      ),
    );
  }
}
