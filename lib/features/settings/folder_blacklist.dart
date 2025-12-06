import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/folders/controllers/folder_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart';
import 'package:kanyoni/utils/services/shared_prefs_service.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

class FolderBlacklistScreen extends StatefulWidget {
  const FolderBlacklistScreen({super.key});

  @override
  State<FolderBlacklistScreen> createState() => _FolderBlacklistScreenState();
}

class _FolderBlacklistScreenState extends State<FolderBlacklistScreen>
    with SingleTickerProviderStateMixin {
  final PlayerController _playerController = Get.find<PlayerController>();
  final FolderController _folderController = Get.find<FolderController>();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<String> _allFolders = [];
  List<String> _blacklistedFolders = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allFolders = await _audioQuery.queryAllPath();
    final blacklistedFolders = await getBlacklistedFolders();
    setState(() {
      _allFolders = allFolders;
      _blacklistedFolders = blacklistedFolders;
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _onToggleBlacklist(String folderPath) async {
    final isBlacklisted = _blacklistedFolders.contains(folderPath);

    setState(() {
      if (isBlacklisted) {
        _blacklistedFolders.remove(folderPath);
      } else {
        _blacklistedFolders.add(folderPath);
      }
    });

    await saveBlacklistedFolders(_blacklistedFolders);
    await _playerController.refreshSongs();
    await _folderController.fetchFolders();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Folder Blacklist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        // Get current song for background artwork
        final currentSongIndex = _playerController.currentSongIndex.value;
        final hasCurrentSong = currentSongIndex >= 0 &&
            currentSongIndex < _playerController.currentPlaylist.length;
        final currentSong = hasCurrentSong
            ? _playerController.currentPlaylist[currentSongIndex]
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : _allFolders.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : _buildFolderList(isDarkMode),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.folder_2,
              size: 80,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Folders Found',
              style: AppTheme.headlineMedium.copyWith(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'No audio folders detected on your device',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(bool isDarkMode) {
    return Column(
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _animationController,
            child: Container(
              padding: const EdgeInsets.all(16),
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.info_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select folders to exclude from your library',
                      style: AppTheme.bodyMedium.copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Folder List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _allFolders.length,
            itemBuilder: (context, index) {
              final folderPath = _allFolders[index];
              final isBlacklisted = _blacklistedFolders.contains(folderPath);

              return FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / _allFolders.length).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOut,
                    ),
                  )),
                  child: _ModernFolderCard(
                    folderPath: folderPath,
                    isBlacklisted: isBlacklisted,
                    isDarkMode: isDarkMode,
                    onToggle: () => _onToggleBlacklist(folderPath),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModernFolderCard extends StatefulWidget {
  final String folderPath;
  final bool isBlacklisted;
  final bool isDarkMode;
  final VoidCallback onToggle;

  const _ModernFolderCard({
    required this.folderPath,
    required this.isBlacklisted,
    required this.isDarkMode,
    required this.onToggle,
  });

  @override
  State<_ModernFolderCard> createState() => _ModernFolderCardState();
}

class _ModernFolderCardState extends State<_ModernFolderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _getFolderName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isBlacklisted
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : (widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02)),
            width: widget.isBlacklisted ? 1.5 : 1,
          ),
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
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _scaleController.forward().then((_) {
                _scaleController.reverse();
              });
              widget.onToggle();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Folder Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isBlacklisted
                          ? Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.15)
                          : (widget.isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isBlacklisted
                          ? Iconsax.folder_minus
                          : Iconsax.folder_2,
                      color: widget.isBlacklisted
                          ? Theme.of(context).primaryColor
                          : (widget.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600]),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Folder Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFolderName(widget.folderPath),
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.isBlacklisted
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.folderPath,
                          style: AppTheme.bodySmall.copyWith(
                            color: widget.isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Checkbox/Toggle Indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isBlacklisted
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isBlacklisted
                            ? Theme.of(context).primaryColor
                            : (widget.isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[400]!),
                        width: 2,
                      ),
                    ),
                    child: widget.isBlacklisted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
