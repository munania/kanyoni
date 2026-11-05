import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:kanyoni/features/lyrics/lyrics_controller.dart';
import 'package:kanyoni/utils/theme/theme.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({super.key});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  late final LyricsController _lyricsController;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  Worker? _scrollWorker;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _lyricsController = Get.find<LyricsController>();

    // The controller only loads lyrics / listens to playback while this view
    // is on screen.
    _lyricsController.activate();

    // Auto-scroll listener
    _scrollWorker = ever(_lyricsController.currentLineIndex, (int index) {
      if (!_isUserScrolling &&
          index >= 0 &&
          _lyricsController.isSynced.value &&
          index < _lyricsController.parsedLyrics.length &&
          _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5, // Center the item
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollWorker?.dispose();
    _lyricsController.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      if (_lyricsController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_lyricsController.isInstrumental.value) {
        return _buildMessage(
          isDarkMode,
          icon: Icons.music_note,
          title: 'Instrumental',
        );
      }

      if (_lyricsController.hasError.value ||
          _lyricsController.parsedLyrics.isEmpty) {
        return _buildEmpty(context, isDarkMode);
      }

      return Stack(
        children: [
          _buildLyricsList(context, isDarkMode),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                if (_lyricsController.isSynced.value)
                  IconButton(
                    tooltip: 'Adjust sync',
                    icon: Icon(
                      Icons.tune,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => _showSyncSheet(context),
                  ),
                IconButton(
                  tooltip: 'Edit lyrics',
                  icon: Icon(
                    Icons.edit,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () => _showEditLyricsDialog(context),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMessage(
    bool isDarkMode, {
    required IconData icon,
    required String title,
    String? subtitle,
    List<Widget> actions = const [],
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.headlineMedium.copyWith(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) {
    final offline = _lyricsController.isOffline.value;
    return _buildMessage(
      isDarkMode,
      icon: offline ? Icons.cloud_off : Icons.lyrics,
      title: offline ? "Can't reach the lyrics service" : 'No lyrics found',
      subtitle: offline
          ? 'Check your internet connection and try again.'
          : 'You can search again or add the lyrics yourself.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: _lyricsController.searchAgain,
          icon: const Icon(Icons.refresh),
          label: const Text('Search again'),
        ),
        FilledButton.icon(
          onPressed: () => _showEditLyricsDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Lyrics'),
        ),
      ],
    );
  }

  Widget _buildLyricsList(BuildContext context, bool isDarkMode) {
    final synced = _lyricsController.isSynced.value;

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          _isUserScrolling = true;
        } else {
          // Resume auto-scroll after a delay when scrolling stops
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _isUserScrolling = false;
              });
            }
          });
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        itemCount: _lyricsController.parsedLyrics.length,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        itemBuilder: (context, index) {
          final line = _lyricsController.parsedLyrics[index];

          // Unsynced lyrics: static text, blank entries are stanza breaks.
          if (!synced) {
            if (line.text.isEmpty) return const SizedBox(height: 20);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  fontSize: 18,
                ),
              ),
            );
          }

          return Obx(() {
            final isCurrentLine =
                index == _lyricsController.currentLineIndex.value;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _lyricsController.seekToLine(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: isCurrentLine
                      ? AppTheme.headlineMedium.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        )
                      : AppTheme.bodyLarge.copyWith(
                          color: isDarkMode
                              ? Colors.grey[600]
                              : Colors.grey[400],
                          fontSize: 18,
                        ),
                  textAlign: TextAlign.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(line.text, textAlign: TextAlign.center),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  String _formatOffset(int ms) {
    final seconds = (ms / 1000).toStringAsFixed(1);
    return ms > 0 ? '+$seconds s' : '$seconds s';
  }

  void _showSyncSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Obx(() {
          final lyrics = _lyricsController.currentLyrics.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Lyrics sync', style: AppTheme.headlineMedium),
              if (lyrics != null && !_lyricsController.isManual.value) ...[
                const SizedBox(height: 8),
                Text(
                  'Matched to: ${lyrics.trackName} - ${lyrics.artistName}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => _lyricsController.adjustOffset(-500),
                    child: const Text('Later  -0.5s'),
                  ),
                  Text(
                    _formatOffset(_lyricsController.offsetMs.value),
                    style: AppTheme.headlineMedium,
                  ),
                  OutlinedButton(
                    onPressed: () => _lyricsController.adjustOffset(500),
                    child: const Text('Earlier  +0.5s'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'If lines change too late, tap "Earlier". If they change too '
                'early, tap "Later". Saved for this song. You can also tap '
                'any line to jump to it.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _lyricsController.offsetMs.value == 0
                        ? null
                        : () => _lyricsController.setOffset(0),
                    child: const Text('Reset sync'),
                  ),
                  const Spacer(),
                  if (!_lyricsController.isManual.value)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _lyricsController.searchAgain();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Wrong lyrics? Search again'),
                    ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showEditLyricsDialog(BuildContext context) {
    final textController = TextEditingController(
      text: _lyricsController.editableText,
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Lyrics', style: AppTheme.headlineMedium),
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: () {
                        // Debug Info
                        Get.defaultDialog(
                          title: 'Lyrics Debug Info',
                          content: Obx(
                            () => Column(
                              children: [
                                Text(
                                  'Matched: ${_lyricsController.currentLyrics.value?.trackName} - ${_lyricsController.currentLyrics.value?.artistName}',
                                ),
                                Text(
                                  'Is Loading: ${_lyricsController.isLoading.value}',
                                ),
                                Text(
                                  'Has Error: ${_lyricsController.hasError.value}',
                                ),
                                Text(
                                  'Synced: ${_lyricsController.isSynced.value}',
                                ),
                                Text(
                                  'Parsed Lines: ${_lyricsController.parsedLyrics.length}',
                                ),
                                Text(
                                  'Current Line: ${_lyricsController.currentLineIndex.value}',
                                ),
                                Text(
                                  'Offset: ${_lyricsController.offsetMs.value} ms',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Text Field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Paste lyrics here. Plain text works, or LRC for synced lyrics:\n[00:12.34] Line 1\n[00:15.67] Line 2',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(
                      fontFamily: 'Monospace',
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      _lyricsController.deleteManualLyrics();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      _lyricsController.saveManualLyrics(textController.text);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
