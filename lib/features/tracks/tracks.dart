// views/tracks_view.dart
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
    final playerController = Get.find<PlayerController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TracksList(
        isDarkMode: isDarkMode, playerController: playerController);
  }
}

class TracksList extends StatefulWidget {
  final PlayerController playerController;
  final bool isDarkMode;

  const TracksList({
    super.key,
    required this.isDarkMode,
    required this.playerController,
  });

  @override
  State<TracksList> createState() => _TracksListState();
}

class _TracksListState extends State<TracksList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      // Only restore scroll position if app was recently closed
      initialScrollOffset: DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(
              widget.playerController.lastAppCloseTime ?? 0
          )
      ) < Duration(minutes: 30)
          ? widget.playerController.listScrollOffset.value
          : 0.0,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    widget.playerController.updateListScrollPosition(_scrollController.offset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.playerController.songs.length,
        itemBuilder: (context, index) {
          final song = widget.playerController.songs[index];
          return ListTile(
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: Icon(
                size: 50,
                Iconsax.music,
                color: widget.isDarkMode
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
            onTap: () => widget.playerController.playSong(index),
          );
        },
      );
    });
  }
}
