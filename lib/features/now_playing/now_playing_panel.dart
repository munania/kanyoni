import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../songDetails/song_details.dart';
import '../lyrics/lyrics.dart';
import 'now_playing_widgets.dart';

/// Opens on a *tap-like* gesture, even if the finger moved a little.
///
/// A plain onTap is cancelled as soon as the finger drifts a few pixels,
/// because the sliding panel's drag recognizer then wins the gesture. The
/// result felt like the bar had frozen. This watches the raw pointer events,
/// which are delivered regardless of which recognizer wins, and opens when the
/// finger went down and up close together in time and place. A real swipe
/// (further than [_slop]) is left to the panel's own drag handling.
class _TapToOpen extends StatefulWidget {
  final VoidCallback onOpen;
  final Widget child;

  const _TapToOpen({required this.onOpen, required this.child});

  @override
  State<_TapToOpen> createState() => _TapToOpenState();
}

class _TapToOpenState extends State<_TapToOpen> {
  static const double _slop = 24;
  static const Duration _maxDuration = Duration(milliseconds: 500);

  Offset? _downAt;
  DateTime? _downTime;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        _downAt = event.position;
        _downTime = DateTime.now();
      },
      onPointerUp: (event) {
        final downAt = _downAt;
        final downTime = _downTime;
        _downAt = null;
        _downTime = null;
        if (downAt == null || downTime == null) return;

        final moved = (event.position - downAt).distance;
        final quick = DateTime.now().difference(downTime) < _maxDuration;
        if (moved < _slop && quick) widget.onOpen();
      },
      onPointerCancel: (_) {
        _downAt = null;
        _downTime = null;
      },
      child: widget.child,
    );
  }
}

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
    void openPanel() {
      // Open unless already fully open. (Checking "is closed" instead meant a
      // panel left part-way up could never be opened by tapping.)
      if (panelController.isAttached && !panelController.isPanelOpen) {
        panelController.open();
      }
    }

    return GestureDetector(
      onTap: openPanel,
      child: Obx(() {
        final currentSong = playerController.activeSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.cornerRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TapToOpen(
                    onOpen: openPanel,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: QueryArtworkWidget(
                            id: currentSong.id,
                            type: ArtworkType.AUDIO,
                            quality: 100,
                            artworkQuality: FilterQuality.high,
                            keepOldArtwork: true,
                            nullArtworkWidget: Icon(Iconsax.music, size: 50),
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
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                      ],
                    ),
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

  const NowPlayingPanel({super.key, required this.playerController});

  @override
  Widget build(BuildContext context) {
    final RxBool showLyrics = false.obs;

    return Obx(() {
      final currentSong = playerController.activeSong;

      if (currentSong == null) {
        return const SizedBox.shrink();
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.cornerRadius),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Artwork/Lyrics Area - Flexible space
                    Expanded(
                      child: Center(
                        child: Obx(() {
                          if (showLyrics.value) {
                            return const LyricsView();
                          }
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.9, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Hero(
                              tag: 'current_artwork',
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => SongDetails(currentSong: currentSong),
                                    transition: Transition.downToUp,
                                  );
                                },
                                child: ArtworkDisplay(song: currentSong),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Song Info
                    SongInfo(song: currentSong),

                    const SizedBox(height: 32),

                    // Controls Area
                    ProgressControls(playerController: playerController),

                    const SizedBox(height: 24),

                    MediaControls(
                      playerController: playerController,
                      isExpanded: true,
                    ),

                    const SizedBox(height: 24),

                    ExtraControls(
                      playerController: playerController,
                      songId: currentSong.id,
                      onLyricsTap: () => showLyrics.toggle(),
                      lyricsVisible: showLyrics,
                    ),

                    const SizedBox(height: 48), // Bottom padding
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
