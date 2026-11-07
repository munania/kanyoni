import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'controllers/player_controller.dart';
import 'features/now_playing/now_playing_panel.dart';
import 'utils/theme/theme.dart';

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({
    super.key,
    required this.child,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late final PanelController
      panelController; // Use late final for single initialization

  /// 0.0 = panel closed (mini player showing), 1.0 = fully open.
  final ValueNotifier<double> _panelPosition = ValueNotifier<double>(0);

  /// Above this the mini player is visually gone, so it must stop taking taps.
  static const double _collapsedTapCutoff = 0.05;

  @override
  void initState() {
    super.initState();
    panelController = PanelController(); // Initialize once in state
  }

  @override
  void dispose() {
    _panelPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Check if panel is NOT closed (open or opening)
        if (!panelController.isPanelClosed) {
          panelController.close();
        } else {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: SlidingUpPanel(
          controller: panelController,
          minHeight: 70,
          maxHeight: MediaQuery.of(context).size.height,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.cornerRadius),
          ),
          onPanelSlide: (position) => _panelPosition.value = position,
          // Explicit end states: if a drag is interrupted the last slide value
          // can be stale, and the mini player must never stay un-tappable
          // while the panel is actually closed.
          onPanelClosed: () => _panelPosition.value = 0,
          onPanelOpened: () => _panelPosition.value = 1,
          panel: NowPlayingPanel(
            playerController: playerController,
          ),
          // The mini player fades out as the panel opens, but it still sits
          // (invisibly) over the top 70px of the open panel. Without this it
          // swallowed taps meant for the controls there, e.g. the lyrics
          // edit/sync buttons triggered play/pause and skip instead.
          collapsed: ValueListenableBuilder<double>(
            valueListenable: _panelPosition,
            builder: (context, position, child) => IgnorePointer(
              ignoring: position > _collapsedTapCutoff,
              child: child,
            ),
            child: CollapsedPanel(
              playerController: playerController,
              panelController: panelController,
            ),
          ),
          body: widget.child,
        ),
      ),
    );
  }
}
