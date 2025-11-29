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

  @override
  void initState() {
    super.initState();
    panelController = PanelController(); // Initialize once in state
  }

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
          panel: NowPlayingPanel(
            playerController: playerController,
          ),
          collapsed: CollapsedPanel(
            playerController: playerController,
            panelController: panelController,
          ),
          body: widget.child,
        ),
      ),
    );
  }
}
