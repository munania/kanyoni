import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/playlist_picker_sheet.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'song_picker_page.dart';

/// The play queue: tap to jump, drag to reorder, swipe to remove, long-press
/// to select several songs (remove them, or save them as a playlist).
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  static const double _rowHeight = 68;

  final PlayerController _player = Get.find<PlayerController>();
  final Set<int> _selected = {};
  late final ScrollController _scroll;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Open with the playing song in view.
    final offset = (_player.currentSongIndex.value - 2) * _rowHeight;
    _scroll = ScrollController(initialScrollOffset: math.max(0.0, offset));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<SongModel> _selectedSongs(List<SongModel> queue) {
    final indices = _selected.where((i) => i < queue.length).toList()..sort();
    return [for (final i in indices) queue[i]];
  }

  void _toggle(int index) {
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
    });
  }

  Future<void> _removeSelected() async {
    final indices = _selected.toList();
    setState(_selected.clear);
    await _player.removeFromQueue(indices);
  }

  PreferredSizeWidget _normalBar(List<SongModel> queue) {
    return AppBar(
      title: Text('Queue (${queue.length})'),
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          tooltip: 'Save queue as playlist',
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: queue.isEmpty
              ? null
              : () => showSaveToPlaylistSheet(
                  context,
                  queue,
                  heading: 'Save queue as playlist',
                ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'clear') _player.clearUpcomingQueue();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'clear',
              child: Text('Clear all except playing'),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _selectionBar(List<SongModel> queue) {
    return AppBar(
      title: Text('${_selected.length} selected'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(_selected.clear),
      ),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: const Icon(Icons.select_all_rounded),
          onPressed: () => setState(() {
            _selected
              ..clear()
              ..addAll(List<int>.generate(queue.length, (i) => i));
          }),
        ),
        IconButton(
          tooltip: 'Save selected as playlist',
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () async {
            final songs = _selectedSongs(queue);
            await showSaveToPlaylistSheet(
              context,
              songs,
              heading: 'Save selected songs',
            );
            if (mounted) setState(_selected.clear);
          },
        ),
        IconButton(
          tooltip: 'Remove from queue',
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: _removeSelected,
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 72,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'The queue is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add songs" to build a queue.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<SongModel> queue, int index, int current) {
    final song = queue[index];
    final primary = Theme.of(context).primaryColor;
    final isCurrent = index == current;
    final isSelected = _selected.contains(index);
    final alreadyPlayed = index < current;

    final tile = Material(
      color: isSelected
          ? primary.withValues(alpha: 0.18)
          : (isCurrent ? primary.withValues(alpha: 0.08) : Colors.transparent),
      child: InkWell(
        onTap: () {
          if (_selecting) {
            _toggle(index);
          } else {
            _player.playSong(index);
          }
        },
        onLongPress: () => _toggle(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: Container(
                      color: primary.withValues(alpha: 0.1),
                      child: Icon(Iconsax.music, color: primary, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isCurrent ? primary : null,
                      ),
                    ),
                    Text(
                      song.artist == null || song.artist == '<unknown>'
                          ? 'Unknown artist'
                          : song.artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isCurrent && !_selecting)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.graphic_eq_rounded, color: primary),
                ),
              if (_selecting)
                Checkbox(value: isSelected, onChanged: (_) => _toggle(index))
              else
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('queue-$index-${song.id}'),
      direction: _selecting
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _player.removeFromQueue([index]),
      child: Opacity(opacity: alreadyPlayed ? 0.55 : 1, child: tile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Obx(() {
        final queue = _player.currentPlaylist.toList();
        final current = _player.currentSongIndex.value;

        return Scaffold(
          appBar: _selecting ? _selectionBar(queue) : _normalBar(queue),
          body: queue.isEmpty
              ? _buildEmpty()
              : ReorderableListView.builder(
                  scrollController: _scroll,
                  buildDefaultDragHandles: false,
                  itemExtent: _rowHeight,
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (_selecting) return;
                    _player.moveInQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) =>
                      _buildRow(queue, index, current),
                ),
          floatingActionButton: _selecting
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SongPickerPage()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add songs'),
                ),
        );
      }),
    );
  }
}
