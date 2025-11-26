import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_forked/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/folder_controller.dart';
import 'folder_grid_card.dart';
import 'folders_details.dart';

class FoldersView extends StatefulWidget {
  const FoldersView({super.key});

  @override
  State<FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<FoldersView>
    with AutomaticKeepAliveClientMixin {
  late final FolderController folderController;
  bool _isGridView = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    folderController = Get.find<FolderController>();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('folders_grid_view') ?? false;
    });
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool('folders_grid_view', _isGridView);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final PlayerController playerController = Get.find();

    return Scaffold(
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
            if (folderController.folders.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.folder_2,
                      size: 80,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Folders Found',
                      style: AppTheme.headlineMedium.copyWith(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your music folders will appear here',
                        style: AppTheme.bodyMedium.copyWith(
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            else
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Toggle Button in SliverAppBar
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 60,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                onTap: _toggleView,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isGridView
                                            ? Iconsax.row_horizontal
                                            : Iconsax.element_4,
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isGridView ? 'List' : 'Grid',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Grid or List View
                  if (_isGridView)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = folderController.folders[index];
                            final songCount =
                                folderController.getSongCount(folder);
                            return FolderGridCard(
                              folderPath: folder,
                              songCount: songCount,
                              onTap: () {
                                Get.to(() =>
                                    FolderDetailsView(folderPath: folder));
                              },
                            );
                          },
                          childCount: folderController.folders.length,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final folder = folderController.folders[index];
                            final songCount =
                                folderController.getSongCount(folder);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.02),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Get.to(() => FolderDetailsView(
                                          folderPath: folder));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Iconsax.folder_25,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  path.basename(folder),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Iconsax.arrow_right_3,
                                            color: isDarkMode
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: folderController.folders.length,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }
}
