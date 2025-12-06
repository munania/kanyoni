import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:kanyoni/utils/helpers/helper_functions.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:kanyoni/controllers/theme_controller.dart';
import 'package:kanyoni/features/equalizer/equalizer_screen.dart';

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

class ThemedArtworkPlaceholder extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? color;

  const ThemedArtworkPlaceholder({
    super.key,
    this.icon = Iconsax.music,
    this.iconSize = 50,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.8),
            primaryColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: 0.5),
        ),
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
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          quality: 100,
          size: 1000,
          artworkQuality: FilterQuality.high,
          nullArtworkWidget: const ThemedArtworkPlaceholder(
            iconSize: 120,
          ),
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
    final themeController = Get.find<ThemeController>();

    // Local state for smooth scrubbing
    final RxBool isDragging = false.obs;
    final Rx<Duration> dragPosition = Duration.zero.obs;

    return Obx(() {
      // Listen to waveform style changes here to force rebuild
      final style = themeController.waveformStyle.value;

      // Get the current song safely
      if (playerController.currentPlaylist.isEmpty ||
          playerController.currentSongIndex.value < 0 ||
          playerController.currentSongIndex.value >=
              playerController.currentPlaylist.length) {
        return const SizedBox(height: 80); // Placeholder height
      }

      final currentSong = playerController
          .currentPlaylist[playerController.currentSongIndex.value];

      // Generate consistent waveform data based on song ID
      final random = Random(currentSong.id);
      final samples = List<double>.generate(
          100, (index) => random.nextDouble().clamp(0.1, 1.0));

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Custom waveform player that syncs with just_audio
            StreamBuilder<PositionData>(
              stream: playerController.positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                final duration = positionData?.duration ?? Duration.zero;
                final position = positionData?.position ?? Duration.zero;

                return Column(
                  children: [
                    SizedBox(
                      height: 50,
                      child: GestureDetector(
                        onHorizontalDragStart: (details) {
                          isDragging.value = true;
                        },
                        onHorizontalDragUpdate: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final localPosition = details.localPosition;
                          final progress = (localPosition.dx / box.size.width)
                              .clamp(0.0, 1.0);
                          dragPosition.value = duration * progress;
                        },
                        onHorizontalDragEnd: (details) {
                          playerController.audioPlayer.seek(dragPosition.value);
                          isDragging.value = false;
                        },
                        onTapDown: (details) {
                          final box = context.findRenderObject() as RenderBox;
                          final localPosition = details.localPosition;
                          final progress = localPosition.dx / box.size.width;
                          final seekPosition = duration * progress;
                          playerController.audioPlayer.seek(seekPosition);
                        },
                        child: Obx(() {
                          final currentPosition =
                              isDragging.value ? dragPosition.value : position;

                          return _buildWaveform(
                            context,
                            style,
                            samples,
                            duration,
                            currentPosition,
                            isDarkMode,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final currentPosition =
                          isDragging.value ? dragPosition.value : position;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(currentPosition),
                            style: AppTheme.bodyMedium,
                          ),
                          Text(
                            _formatDuration(duration),
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWaveform(
    BuildContext context,
    String style,
    List<double> samples,
    Duration duration,
    Duration position,
    bool isDarkMode,
  ) {
    final width = MediaQuery.of(context).size.width - 48;
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    // Ensure maxDuration is never zero to prevent assertion errors
    final safeDuration =
        duration.inMilliseconds > 0 ? duration : const Duration(seconds: 1);

    switch (style) {
      case 'Rectangle':
        return RectangleWaveform(
          samples: samples,
          height: 50,
          width: width,
          maxDuration: safeDuration,
          elapsedDuration: position,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          showActiveWaveform: true,
          absolute: true,
          invert: false,
        );
      case 'Squiggly':
        return SquigglyWaveform(
          samples: samples,
          height: 50,
          width: width,
          maxDuration: safeDuration,
          elapsedDuration: position,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          showActiveWaveform: true,
          absolute: false,
          invert: false,
          strokeWidth: 2.0,
        );
      case 'Curved':
        return CurvedPolygonWaveform(
          samples: samples,
          height: 50,
          width: width,
          maxDuration: safeDuration,
          elapsedDuration: position,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          showActiveWaveform: true,
          absolute: true,
          invert: false,
        );
      case 'Polygon':
      default:
        return PolygonWaveform(
          samples: samples,
          height: 50,
          width: width,
          maxDuration: safeDuration,
          elapsedDuration: position,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          style: PaintingStyle.fill,
          showActiveWaveform: true,
          absolute: true,
          invert: false,
        );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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
        /// Shuffle Button
        Obx(() {
          final isShuffle = playerController.isShuffle.value;
          return IconButton(
            icon: const Icon(Iconsax.shuffle),
            onPressed: playerController.toggleShuffle,
            iconSize: 24,
            color: isShuffle
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          );
        }),

        /// Previous Button
        IconButton(
          icon: const Icon(Iconsax.previous),
          onPressed: playerController.playPrevious,
          iconSize: 32,
          color: Theme.of(context).iconTheme.color,
        ),

        /// Play/Pause Button
        Obx(
          () => ScaleButton(
            onTap: playerController.togglePlayPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                playerController.isPlaying.value ? Iconsax.pause : Iconsax.play,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),

        /// Next Button
        IconButton(
          icon: const Icon(Iconsax.next),
          onPressed: playerController.playNext,
          iconSize: 32,
          color: Theme.of(context).iconTheme.color,
        ),

        /// Repeat Button
        /// Repeat Button
        Obx(() {
          final mode = playerController.repeatMode.value;
          return IconButton(
            icon: Icon(_getRepeatIcon(mode)),
            onPressed: playerController.toggleRepeatMode,
            iconSize: 24,
            color: mode != RepeatMode.off
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          );
        }),
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
        return Iconsax.repeat;
    }
  }
}

class ExtraControls extends StatelessWidget {
  final PlayerController playerController;
  final int songId;
  final VoidCallback onLyricsTap;

  const ExtraControls({
    super.key,
    required this.playerController,
    required this.songId,
    required this.onLyricsTap,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize = 22;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // Changed to spaceBetween
      children: [
        ScaleButton(
          onTap: onLyricsTap,
          child: Icon(
            Iconsax.book,
            size: iconSize,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        ScaleButton(
          onTap: () {
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
          child: Obx(() {
            // Defensive checks
            if (playerController.currentPlaylist.isEmpty ||
                playerController.currentSongIndex.value < 0 ||
                playerController.currentSongIndex.value >=
                    playerController.currentPlaylist.length) {
              // Return a default icon state if no valid song is selected/playing
              return Icon(
                Icons.favorite_border,
                size: iconSize, // Default non-favourite icon
                color: Theme.of(context).iconTheme.color,
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
              color:
                  isFavorite ? Colors.red : Theme.of(context).iconTheme.color,
            );
          }),
        ),
        GetBuilder<PlaylistController>(builder: (playlistCtrl) {
          return ScaleButton(
            onTap: () {
              // Ensure current song is available
              if (playerController.currentPlaylist.isEmpty ||
                  playerController.currentSongIndex.value < 0 ||
                  playerController.currentSongIndex.value >=
                      playerController.currentPlaylist.length) {
                Get.snackbar('Error', 'No song currently playing or selected.');
                return;
              }
              final currentSong = playerController
                  .currentPlaylist[playerController.currentSongIndex.value];

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add to Playlist',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Iconsax.add,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: const Text('Create New Playlist'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onTap: () {
                                Navigator.pop(
                                    context); // Close bottom sheet first
                                final nameController = TextEditingController();
                                Get.generalDialog(
                                  barrierDismissible: true,
                                  barrierLabel: 'Dismiss',
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                    return Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.85,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'New Playlist',
                                                style: AppTheme.headlineMedium,
                                              ),
                                              const SizedBox(height: 16),
                                              TextField(
                                                controller: nameController,
                                                decoration: InputDecoration(
                                                  hintText: 'Playlist Name',
                                                  hintStyle: TextStyle(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color
                                                        ?.withValues(
                                                            alpha: 0.5),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  filled: true,
                                                  fillColor: Theme.of(context)
                                                      .cardColor
                                                      .withValues(alpha: 0.5),
                                                  contentPadding:
                                                      const EdgeInsets.all(16),
                                                ),
                                                autofocus: true,
                                                style: AppTheme.bodyMedium,
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Theme.of(context)
                                                              .iconTheme
                                                              .color,
                                                    ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  FilledButton(
                                                    onPressed: () async {
                                                      if (nameController.text
                                                          .trim()
                                                          .isEmpty) {
                                                        Get.snackbar('Error',
                                                            'Playlist name cannot be empty.');
                                                        return;
                                                      }

                                                      final playlistName =
                                                          nameController.text
                                                              .trim();
                                                      Navigator.of(context)
                                                          .pop();

                                                      final newPlaylist =
                                                          await playlistCtrl
                                                              .createPlaylist(
                                                                  playlistName);

                                                      if (newPlaylist != null) {
                                                        final success =
                                                            await playlistCtrl
                                                                .addToPlaylist(
                                                                    newPlaylist
                                                                        .id,
                                                                    currentSong
                                                                        .id);
                                                        if (success) {
                                                          Get.snackbar(
                                                              'Success',
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
                                                    style:
                                                        FilledButton.styleFrom(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                    child: const Text('Create'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  transitionBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return Transform.scale(
                                      scale: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutBack,
                                      ).value,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                );
                              },
                            ),
                            const Divider(),
                            ...playlistCtrl.playlists.map((playlist) {
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Iconsax.music_playlist,
                                    color: Theme.of(context).iconTheme.color,
                                  ),
                                ),
                                title: Text(playlist.playlist),
                                subtitle: Text(
                                    '${playlist.numOfSongs} songs'), // Assuming numOfSongs exists or similar
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final success =
                                      await playlistCtrl.addToPlaylist(
                                          playlist.id, currentSong.id);
                                  if (success) {
                                    Get.snackbar('Success',
                                        'Added "${currentSong.title}" to "${playlist.playlist}"');
                                  } else {
                                    Get.snackbar('Error',
                                        'Failed to add "${currentSong.title}" to "${playlist.playlist}"');
                                  }
                                },
                              );
                            }),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Icon(
              Iconsax.add_circle,
              size: iconSize,
              color: Theme.of(context).iconTheme.color,
            ),
          );
        }),
        ScaleButton(
          onTap: () {
            Get.to(
              () => const EqualizerScreen(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          },
          child: Icon(
            Iconsax.setting_4,
            size: iconSize,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        ScaleButton(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) =>
                  _SleepTimerSheet(controller: playerController),
            );
          },
          child: Obx(() {
            final isActive = playerController.sleepTimerActive.value;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: isActive
                  ? BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                Iconsax.timer_1,
                size: iconSize,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).iconTheme.color,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final Duration duration;
  final double scale;

  const ScaleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.duration = const Duration(milliseconds: 50),
    this.scale = 0.9,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final PlayerController controller;

  const _SleepTimerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sleep Timer',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.sleepTimerActive.value) {
              final remaining = controller.sleepTimerRemaining.value;
              final minutes = remaining ~/ 60;
              final seconds = remaining % 60;
              return Text(
                'Stopping in ${minutes}m ${seconds}s',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return Text(
              'Stop audio after...',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
            );
          }),
          const SizedBox(height: 24),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildTimerOption(context, 5),
                _buildTimerOption(context, 10),
                _buildTimerOption(context, 15),
                _buildTimerOption(context, 30),
                _buildTimerOption(context, 45),
                _buildTimerOption(context, 60),
                _buildCustomTimerOption(context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.sleepTimerActive.value) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Turn Off Timer'),
                  ),
                ),
              );
            }
            return const SizedBox(height: 32);
          }),
        ],
      ),
    );
  }

  Widget _buildTimerOption(BuildContext context, int minutes) {
    return Obx(() {
      final isSelected = controller.sleepTimerActive.value &&
          controller.sleepTimerDuration.value == minutes * 60;

      return InkWell(
        onTap: () {
          controller.startSleepTimer(minutes);
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 300), () {
            Get.snackbar(
              'Sleep Timer Set',
              'Audio will stop in $minutes minutes',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$minutes min',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCustomTimerOption(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomTimerDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Custom',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Custom Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter duration in minutes:'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Minutes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(textController.text);
              if (minutes != null && minutes > 0) {
                controller.startSleepTimer(minutes);
                Get.back(); // Close dialog
                Navigator.pop(context); // Close sheet

                Future.delayed(const Duration(milliseconds: 300), () {
                  Get.snackbar(
                    'Sleep Timer Set',
                    'Audio will stop in $minutes minutes',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                });
              } else {
                Get.snackbar(
                  'Invalid Duration',
                  'Please enter a valid number of minutes',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  colorText: Colors.red,
                );
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
