import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/features/playlists/playlist_card.dart';
import 'package:kanyoni/features/playlists/playlists_details.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'controller/playlists_controller.dart';

class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key});

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView>
    with AutomaticKeepAliveClientMixin {
  late final PlaylistController controller;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PlaylistController>();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final PlayerController playerController = Get.find();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash, size: 24),
            onPressed: () => _showClearAllDialog(),
          ),
          IconButton(
            icon: const Icon(Iconsax.add_square, size: 30),
            onPressed: () => _showCreatePlaylistDialog(),
          ),
        ],
      ),
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
            SafeArea(
              child: controller.playlists.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildPlaylistList(isDarkMode),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.music_playlist,
            size: 80,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Playlists Yet',
            style: AppTheme.headlineMedium.copyWith(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create a playlist to organize your favorite songs',
              style: AppTheme.bodyMedium.copyWith(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistList(bool isDarkMode) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: controller.playlists.length,
      itemBuilder: (context, index) {
        final playlist = controller.playlists[index];
        return PlaylistCard(
          playlist: playlist,
          isDarkMode: isDarkMode,
          onTap: () => Get.to(() => PlaylistDetailsView(playlist: playlist)),
          onRename: () => _showRenamePlaylistDialog(playlist),
          onDelete: () => _showDeletePlaylistDialog(playlist),
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    _showNameDialog(
      title: 'Create Playlist',
      hint: 'Enter playlist name',
      confirmLabel: 'Create',
      initialText: '',
      onConfirm: (name) => controller.createPlaylist(name),
    );
  }

  void _showRenamePlaylistDialog(PlaylistModel playlist) {
    _showNameDialog(
      title: 'Rename Playlist',
      hint: 'Enter new name',
      confirmLabel: 'Rename',
      initialText: playlist.playlist.replaceAll(' [kanyoni]', ''),
      ignoreId: playlist.id,
      onConfirm: (name) => controller.renamePlaylist(playlist.id, name),
    );
  }

  /// Shared create/rename dialog. It validates before closing, so a blank or
  /// duplicate name shows an error in the dialog instead of silently making a
  /// second playlist with the same name.
  void _showNameDialog({
    required String title,
    required String hint,
    required String confirmLabel,
    required String initialText,
    required void Function(String name) onConfirm,
    int? ignoreId,
  }) {
    final nameController = TextEditingController(text: initialText);
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final problem =
                controller.validateName(nameController.text, ignoreId: ignoreId);
            if (problem != null) {
              setDialogState(() => error = problem);
              return;
            }
            Navigator.pop(dialogContext);
            onConfirm(nameController.text);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(title),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                hintText: hint,
                errorText: error,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (error != null) setDialogState(() => error = null);
              },
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submit,
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Playlist'),
        content:
            Text('Are you sure you want to delete "${playlist.playlist}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deletePlaylist(playlist.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Clear All Playlists'),
        content: const Text(
            'Are you sure you want to delete ALL playlists? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.clearAllPlaylists();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
