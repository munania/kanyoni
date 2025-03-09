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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playerController = Get.find<PlayerController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = _playerController.songs[index];
                return _TrackListItem(
                  song: song,
                  index: index,
                  isDarkMode: isDarkMode,
                  playerController: _playerController,
                );
              },
              childCount: _playerController.songs.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackListItem extends StatelessWidget {
  final SongModel song;
  final int index;
  final bool isDarkMode;
  final PlayerController playerController;

  const _TrackListItem({
    required this.song,
    required this.index,
    required this.isDarkMode,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          size: 50,
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
          song.artist ?? 'Unknown Artist',
          style: AppTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => playerController.playSong(song),
      ),
    );
  }
}
