import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart'; // Import PlaylistController
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../utils/theme/theme.dart';
import 'features/lyrics/lyrics.dart';
import 'features/songDetails/song_details.dart';

class CollapsedPanel extends StatelessWidget {
  final PlayerController playerController;
  final PanelController panelController;

  const CollapsedPanel({
    super.key,
    required this.playerController,
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
        if (kDebugMode) {
          print(
              '[CollapsedPanel.Obx] Playlist length: ${playlist.length}, Index: $index');
        } // Log here

        // Check bounds
        if (playlist.isEmpty || index < 0 || index >= playlist.length) {
          if (kDebugMode) {
            print('[CollapsedPanel.Obx] Conditions met to shrink panel.');
          } // Log here
          return const SizedBox.shrink();
        }

        final currentSong = playlist[index];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
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
                    quality: 100,
                    artworkQuality: FilterQuality.high,
                    nullArtworkWidget: Icon(
                      Iconsax.music,
                      size: 50,
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
                  isExpanded: false,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class NowPlayingPanel extends StatelessWidget {
  final PlayerController playerController;

  const NowPlayingPanel({
    super.key,
    required this.playerController,
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

      return Scaffold(
        body: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cornerRadius),
            ),
          ),
          child: Column(
            children: [
              // const DragHandle(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                        onTap: () {
                          Get.to(
                            () => SongDetails(currentSong: currentSong),
                          );
                        },
                        child: ArtworkDisplay(song: currentSong)),
                    SongInfo(song: currentSong),
                    ProgressControls(
                      playerController: playerController,
                    ),
                    MediaControls(
                      playerController: playerController,
                      isExpanded: true,
                    ),
                    ExtraControls(
                      playerController: playerController,
                      songId: currentSong.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  const ArtworkDisplay({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 100,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QueryArtworkWidget(
        id: song.id,
        type: ArtworkType.AUDIO,
        quality: 100,
        size: 1000,
        artworkQuality: FilterQuality.high,
        nullArtworkWidget: Icon(
          Iconsax.music,
          size: 150,
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

  const ProgressControls({
    super.key,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);
    return Column(
      children: [
        StreamBuilder<PositionData>(
          stream: playerController.positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            return ProgressBar(
              barCapShape: BarCapShape.round,
              barHeight: 3.5,
              progress: positionData?.position ?? Duration.zero,
              buffered: Duration.zero,
              total: positionData?.duration ?? Duration.zero,
              onSeek: playerController.audioPlayer.seek,
              baseBarColor: isDarkMode ? Colors.grey[700] : Colors.grey[400],
              bufferedBarColor: Colors.transparent,
              thumbGlowRadius: 20.0,
              timeLabelType: TimeLabelType.totalTime,
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
  final bool isExpanded;

  const MediaControls({
    super.key,
    required this.playerController,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Iconsax.previous),
            onPressed: playerController.playPrevious,
            color: Theme.of(context).primaryColor,
          ),
          Obx(() => IconButton(
                icon: Icon(
                  playerController.isPlaying.value
                      ? Iconsax.pause
                      : Iconsax.play,
                ),
                onPressed: playerController.togglePlayPause,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
            icon: const Icon(Iconsax.next),
            onPressed: playerController.playNext,
            color: Theme.of(context).primaryColor,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        /// Shuffle Button
        IconButton(
          icon: Obx(() => Icon(
                playerController.isShuffle.value
                    ? Icons.shuffle_on_rounded
                    : Iconsax.shuffle,
              )),
          onPressed: playerController.toggleShuffle,
          iconSize: 30,
          color: Theme.of(context).primaryColor,
        ),

        /// Previous Button
        IconButton(
          icon: const Icon(Iconsax.previous),
          onPressed: playerController.playPrevious,
          iconSize: 35,
          color: Theme.of(context).primaryColor,
        ),

        /// Play/Pause Button
        Obx(
          () => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: Icon(
                  playerController.isPlaying.value
                      ? Iconsax.pause //Pause icon
                      : Iconsax.play, // Play icon
                ),
                onPressed: playerController.togglePlayPause,
                iconSize: 40,
                color: Theme.of(context).primaryColor,
              )),
        ),

        /// Next Button
        IconButton(
          icon: const Icon(Iconsax.next),
          onPressed: playerController.playNext,
          iconSize: 35,
          color: Theme.of(context).primaryColor,
        ),

        /// Repeat Button
        IconButton(
          icon: Obx(() => Icon(
                _getRepeatIcon(playerController.repeatMode.value),
              )),
          onPressed: playerController.toggleRepeatMode,
          iconSize: 30,
          color: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Iconsax.repeat;
      case RepeatMode.one:
        return Iconsax.repeate_one;
      case RepeatMode.all:
        return Icons.repeat_on_rounded;
    }
  }
}

class ExtraControls extends StatelessWidget {
  final PlayerController playerController;
  final int songId;

  const ExtraControls({
    super.key,
    required this.playerController,
    required this.songId,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = 22;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // Changed to spaceBetween
      children: [
        IconButton(
            onPressed: () {
              Get.to(() => Lyrics(songId: songId));
            },
            icon: Icon(
              Iconsax.book,
              size: iconSize,
              color: Theme.of(context).primaryColor,
            )),
        IconButton(
          icon: Obx(() {
            // Defensive checks
            if (playerController.currentPlaylist.isEmpty ||
                playerController.currentSongIndex.value < 0 ||
                playerController.currentSongIndex.value >=
                    playerController.currentPlaylist.length) {
              // Return a default icon state if no valid song is selected/playing
              return Icon(
                Icons.favorite_border,
                size: iconSize, // Default non-favourite icon
                color: Theme.of(context).primaryColor,
              );
            }

            // If checks pass, proceed to get currentSong
            final currentSong = playerController
                .currentPlaylist[playerController.currentSongIndex.value];
            final bool isFavorite =
                playerController.favoriteSongs.contains(currentSong.id);

            return Icon(
              isFavorite ? Iconsax.heart5 : Iconsax.heart,
              size: iconSize,
              color: Theme.of(context).primaryColor,
            );
          }),
          onPressed: () {
            // Defensive check for onPressed as well
            if (playerController.currentPlaylist.isEmpty ||
                playerController.currentSongIndex.value < 0 ||
                playerController.currentSongIndex.value >=
                    playerController.currentPlaylist.length) {
              Get.snackbar("Error", "No song selected to toggle favorite.");
              return;
            }
            final currentSong = playerController
                .currentPlaylist[playerController.currentSongIndex.value];
            playerController.toggleFavorite(currentSong.id);
          },
          iconSize: 30,
        ),
        GetBuilder<PlaylistController>(builder: (playlistCtrl) {
          // playlistCtrl is the instance from GetBuilder
          return PopupMenuButton<String>(
            icon: Icon(
              Iconsax.add_circle,
              size: iconSize,
              color: Theme.of(context).primaryColor,
            ),
            onSelected: (String value) async {
              // Ensure current song is available (using playerController from ExtraControls)
              if (playerController.currentPlaylist.isEmpty ||
                  playerController.currentSongIndex.value < 0 ||
                  playerController.currentSongIndex.value >=
                      playerController.currentPlaylist.length) {
                Get.snackbar('Error', 'No song currently playing or selected.');
                return;
              }
              final currentSong = playerController
                  .currentPlaylist[playerController.currentSongIndex.value];

              if (value == '__CREATE_NEW__') {
                final nameController = TextEditingController();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Create New Playlist'),
                    content: TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(hintText: 'Playlist Name'),
                      autofocus: true,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            Get.snackbar(
                                'Error', 'Playlist name cannot be empty.');
                            return;
                          }

                          final playlistName = nameController.text.trim();
                          Get.back();

                          await playlistCtrl
                              .createPlaylist(playlistName); // Use playlistCtrl

                          await Future.delayed(
                              const Duration(milliseconds: 300));
                          final newPlaylist = playlistCtrl.playlists
                              .firstWhereOrNull(// Use playlistCtrl
                                  (p) =>
                                      p.playlist == playlistName ||
                                      p.playlist == playlistName);

                          if (newPlaylist != null) {
                            final success = await playlistCtrl.addToPlaylist(
                                newPlaylist.id,
                                currentSong.id); // Use playlistCtrl
                            if (success) {
                              Get.snackbar('Success',
                                  'Added "${currentSong.title}" to "${newPlaylist.playlist}"');
                            } else {
                              Get.snackbar('Error',
                                  'Failed to add "${currentSong.title}" to "${newPlaylist.playlist}"');
                            }
                          } else {
                            Get.snackbar('Error',
                                'Playlist "$playlistName" created, but could not find it to add song. Please try adding manually.');
                          }
                        },
                        child: const Text('Create & Add'),
                      ),
                    ],
                  ),
                );
              } else {
                // Existing playlist
                try {
                  final playlistId = int.parse(value);
                  // Use playlistCtrl to find the playlist
                  final playlist = playlistCtrl.playlists
                      .firstWhereOrNull((p) => p.id == playlistId);
                  if (playlist == null) {
                    Get.snackbar('Error', 'Playlist not found.');
                    return;
                  }
                  // Use playlistCtrl to add to playlist
                  final success = await playlistCtrl.addToPlaylist(
                      playlistId, currentSong.id);
                  if (success) {
                    Get.snackbar('Success',
                        'Added "${currentSong.title}" to "${playlist.playlist}"');
                  } else {
                    Get.snackbar('Error',
                        'Failed to add "${currentSong.title}" to "${playlist.playlist}"');
                  }
                } catch (e) {
                  Get.snackbar(
                      'Error', 'Invalid playlist ID or error: ${e.toString()}');
                }
              }
            },
            itemBuilder: (BuildContext popupContext) {
              final items = <PopupMenuEntry<String>>[];
              // Use playlistCtrl.playlists to build items
              for (var playlist in playlistCtrl.playlists) {
                items.add(PopupMenuItem<String>(
                  value: playlist.id.toString(),
                  child: Text(playlist.playlist),
                ));
              }
              // Use playlistCtrl.playlists to check if not empty
              if (playlistCtrl.playlists.isNotEmpty) {
                items.add(const PopupMenuDivider());
              }
              items.add(const PopupMenuItem<String>(
                value: '__CREATE_NEW__',
                child: Text('Create New Playlist'),
              ));
              return items;
            },
          );
        }),
        IconButton(
          icon: Icon(
            Icons.equalizer_rounded,
            size: iconSize,
            color: Theme.of(context).primaryColor,
          ),
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
          icon: Icon(
            Icons.timer_rounded,
            size: iconSize,
            color: Theme.of(context).primaryColor,
          ),
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
