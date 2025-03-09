import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../utils/theme/theme.dart';

class CollapsedPanel extends StatelessWidget {
  final PlayerController playerController;
  final PanelController panelController;
  final bool isDarkMode;

  const CollapsedPanel({
    super.key,
    required this.playerController,
    required this.isDarkMode,
    required this.panelController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Add safety check before opening
        if (panelController.isAttached) {
          panelController.open();
        }
      },
      child: Obx(() {
        // Get the current values safely
        final List<SongModel> playlist =
            List.from(playerController.currentPlaylist);
        final int index = playerController.currentSongIndex.value;

        // Check bounds
        if (playlist.isEmpty || index < 0 || index >= playlist.length) {
          return const SizedBox.shrink();
        }

        final currentSong = playlist[index];
        final backgroundColor =
            isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cornerRadius),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: QueryArtworkWidget(
                  id: currentSong.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Icon(
                    Iconsax.music,
                    size: 50,
                    color: isDarkMode
                        ? AppTheme.playerControlsDark
                        : AppTheme.playerControlsLight,
                  ),
                  size: 50,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSong.title,
                      style: AppTheme.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentSong.artist ?? 'Unknown Artist',
                      style: AppTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              MediaControls(
                playerController: playerController,
                isDarkMode: isDarkMode,
                isExpanded: false,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class NowPlayingPanel extends StatelessWidget {
  final PlayerController playerController;
  final bool isDarkMode;

  const NowPlayingPanel({
    super.key,
    required this.playerController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (playerController.songs.isEmpty ||
          playerController.currentSongIndex.value >=
              playerController.songs.length) {
        return const SizedBox.shrink();
      }

      final currentSong = playerController
          .currentPlaylist[playerController.currentSongIndex.value];
      final backgroundColor =
          isDarkMode ? AppTheme.nowPlayingDark : AppTheme.nowPlayingLight;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.cornerRadius),
          ),
        ),
        child: Column(
          children: [
            const DragHandle(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ArtworkDisplay(song: currentSong, isDarkMode: isDarkMode),
                  SongInfo(song: currentSong),
                  ProgressControls(
                      playerController: playerController,
                      isDarkMode: isDarkMode),
                  MediaControls(
                    playerController: playerController,
                    isDarkMode: isDarkMode,
                    isExpanded: true,
                  ),
                  ExtraControls(
                      playerController: playerController,
                      isDarkMode: isDarkMode),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class ArtworkDisplay extends StatelessWidget {
  final SongModel song;
  final bool isDarkMode;

  const ArtworkDisplay({
    super.key,
    required this.song,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black..withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: Icon(
          Iconsax.music,
          size: 150,
          color: isDarkMode
              ? AppTheme.playerControlsDark
              : AppTheme.playerControlsLight,
        ),
      ),
    );
  }
}

class SongInfo extends StatelessWidget {
  final SongModel song;

  const SongInfo({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          width: double.infinity,
          child: Marquee(
            text: song.title,
            style: AppTheme.headlineMedium,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 20.0,
            velocity: 50.0,
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          song.artist ?? 'Unknown Artist',
          style: AppTheme.bodyLarge,
        ),
      ],
    );
  }
}

class ProgressControls extends StatelessWidget {
  final PlayerController playerController;
  final bool isDarkMode;

  const ProgressControls({
    super.key,
    required this.playerController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<PositionData>(
          stream: playerController.positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return ProgressBar(
              progress: positionData?.position ?? Duration.zero,
              buffered: Duration.zero,
              total: positionData?.duration ?? Duration.zero,
              onSeek: playerController.audioPlayer.seek,
              baseBarColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              progressBarColor: isDarkMode
                  ? AppTheme.progressBarDark
                  : AppTheme.progressBarLight,
              bufferedBarColor: Colors.transparent,
              thumbColor: isDarkMode
                  ? AppTheme.progressBarDark
                  : AppTheme.progressBarLight,
              timeLabelTextStyle: AppTheme.bodyMedium,
            );
          },
        ),
      ],
    );
  }
}

class MediaControls extends StatelessWidget {
  final PlayerController playerController;
  final bool isDarkMode;
  final bool isExpanded;

  const MediaControls({
    super.key,
    required this.playerController,
    required this.isDarkMode,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isDarkMode ? AppTheme.playerControlsDark : AppTheme.playerControlsLight;

    if (!isExpanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Iconsax.previous),
            onPressed: playerController.playPrevious,
            color: iconColor,
          ),
          Obx(() => IconButton(
                icon: Icon(
                  playerController.isPlaying.value
                      ? Iconsax.pause
                      : Iconsax.play,
                ),
                onPressed: playerController.togglePlayPause,
                color: iconColor,
              )),
          IconButton(
            icon: const Icon(Iconsax.next),
            onPressed: playerController.playNext,
            color: iconColor,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Obx(() => Icon(
                playerController.isShuffle.value
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,
                color: playerController.isShuffle.value
                    ? AppTheme.playerControlsDark
                    : iconColor,
              )),
          onPressed: playerController.toggleShuffle,
          iconSize: 30,
        ),
        IconButton(
          icon: const Icon(Iconsax.previous),
          onPressed: playerController.playPrevious,
          iconSize: 35,
          color: iconColor,
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor,
          ),
          padding: const EdgeInsets.all(8),
          child: Obx(() => IconButton(
                icon: Icon(
                  playerController.isPlaying.value
                      ? Iconsax.pause
                      : Iconsax.play,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
                onPressed: playerController.togglePlayPause,
                iconSize: 40,
              )),
        ),
        IconButton(
          icon: const Icon(Iconsax.next),
          onPressed: playerController.playNext,
          iconSize: 35,
          color: iconColor,
        ),
        IconButton(
          icon: Obx(() => Icon(
                _getRepeatIcon(playerController.repeatMode.value),
                color: playerController.repeatMode.value != RepeatMode.off
                    ? AppTheme.playerControlsDark
                    : iconColor,
              )),
          onPressed: playerController.toggleRepeatMode,
          iconSize: 30,
        ),
      ],
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat_on;
    }
  }
}

class ExtraControls extends StatelessWidget {
  final PlayerController playerController;
  final bool isDarkMode;

  const ExtraControls({
    super.key,
    required this.playerController,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        isDarkMode ? AppTheme.playerControlsDark : AppTheme.playerControlsLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Obx(() {
            final currentSong = playerController
                .currentPlaylist[playerController.currentSongIndex.value];
            return Icon(
              playerController.favoriteSongs.contains(currentSong.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: playerController.favoriteSongs.contains(currentSong.id)
                  ? AppTheme.playerControlsDark
                  : iconColor,
            );
          }),
          onPressed: () {
            final currentSong = playerController
                .currentPlaylist[playerController.currentSongIndex.value];
            playerController.toggleFavorite(currentSong.id);
          },
          iconSize: 30,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.playlist_add, color: iconColor, size: 30),
          onSelected: (value) {
            // TODO: Implement playlist addition
            Get.snackbar(
              'Add to Playlist',
              'Added to $value',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'Custom Playlist',
              child: Text('Create New Playlist'),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.equalizer, color: iconColor, size: 30),
          onPressed: () {
            // TODO: Implement equalizer
            Get.snackbar(
              'Equalizer',
              'Coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.timer, color: iconColor, size: 30),
          onPressed: () {
            // TODO: Implement sleep timer
            Get.snackbar(
              'Sleep Timer',
              'Coming soon!',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ],
    );
  }
}
