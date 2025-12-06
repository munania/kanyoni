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
    _lyricsController = Get.put(LyricsController());

    // Auto-scroll listener
    _scrollWorker = ever(_lyricsController.currentLineIndex, (index) {
      if (!_isUserScrolling &&
          _lyricsController.parsedLyrics.isNotEmpty &&
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return Stack(
        children: [
          if (_lyricsController.isLoading.value)
            const Center(child: CircularProgressIndicator())
          else if (_lyricsController.hasError.value ||
              _lyricsController.parsedLyrics.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lyrics,
                    size: 64,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No lyrics available',
                    style: AppTheme.headlineMedium.copyWith(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showEditLyricsDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Lyrics'),
                  ),
                ],
              ),
            )
          else
            NotificationListener<UserScrollNotification>(
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
                padding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                itemBuilder: (context, index) {
                  final line = _lyricsController.parsedLyrics[index];
                  return Obx(() {
                    final isCurrentLine =
                        index == _lyricsController.currentLineIndex.value;
                    return Padding(
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
                        child: Text(line.text),
                      ),
                    );
                  });
                },
              ),
            ),
          // Always show the edit button in the top right if we have lyrics
          if (!_lyricsController.isLoading.value &&
              !_lyricsController.hasError.value &&
              _lyricsController.parsedLyrics.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => _showEditLyricsDialog(context),
              ),
            ),
        ],
      );
    });
  }

  void _showEditLyricsDialog(BuildContext context) {
    final textController = TextEditingController(
      text: _lyricsController.currentLyrics.value?.syncedLyrics ?? '',
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
                  Text(
                    'Edit Lyrics',
                    style: AppTheme.headlineMedium,
                  ),
                  if (kDebugMode)
                    IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: () {
                        // Debug Info
                        Get.defaultDialog(
                          title: 'Lyrics Debug Info',
                          content: Obx(() => Column(
                                children: [
                                  Text(
                                      'Song ID: ${_lyricsController.currentLyrics.value?.id}'),
                                  Text(
                                      'Is Loading: ${_lyricsController.isLoading.value}'),
                                  Text(
                                      'Has Error: ${_lyricsController.hasError.value}'),
                                  Text(
                                      'Parsed Lines: ${_lyricsController.parsedLyrics.length}'),
                                  Text(
                                      'Current Line: ${_lyricsController.currentLineIndex.value}'),
                                ],
                              )),
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
                      hintText:
                          'Paste LRC lyrics here...\n[00:12.34] Line 1\n[00:15.67] Line 2',
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
                          horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Reset'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
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
                          horizontal: 32, vertical: 16),
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
