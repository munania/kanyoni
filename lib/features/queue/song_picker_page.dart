import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

/// Pick songs from the library and put them in the queue: right after the
/// playing song ("Play next") or at the end ("Add to queue").
class SongPickerPage extends StatefulWidget {
  const SongPickerPage({super.key});

  @override
  State<SongPickerPage> createState() => _SongPickerPageState();
}

class _SongPickerPageState extends State<SongPickerPage> {
  final PlayerController _player = Get.find<PlayerController>();
  final TextEditingController _search = TextEditingController();

  /// Song ids in the order they were ticked (Dart sets keep insertion order).
  final Set<int> _picked = {};
  late final List<SongModel> _library;
  late final Map<int, SongModel> _byId;
  List<SongModel> _visible = const [];

  @override
  void initState() {
    super.initState();
    _library = _player.songs.toList();
    _byId = {for (final s in _library) s.id: s};
    _visible = _library;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _visible = q.isEmpty
          ? _library
          : _library
                .where(
                  (s) =>
                      s.title.toLowerCase().contains(q) ||
                      (s.artist ?? '').toLowerCase().contains(q) ||
                      (s.album ?? '').toLowerCase().contains(q),
                )
                .toList();
    });
  }

  List<SongModel> get _pickedSongs => [
    for (final id in _picked)
      if (_byId[id] != null) _byId[id]!,
  ];

  Future<void> _commit({required bool playNext}) async {
    final songs = _pickedSongs;
    if (songs.isEmpty) return;
    if (playNext) {
      await _player.playNextInQueue(songs);
    } else {
      await _player.addToQueue(songs);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    final n = songs.length;
    Get.snackbar(
      'Queue',
      playNext
          ? '$n ${n == 1 ? 'song' : 'songs'} will play next'
          : 'Added $n ${n == 1 ? 'song' : 'songs'} to the queue',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final count = _picked.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(count == 0 ? 'Add songs' : '$count selected'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: _filter,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search songs',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _visible.isEmpty
          ? const Center(child: Text('No songs found'))
          : ListView.builder(
              itemCount: _visible.length,
              itemExtent: 64,
              itemBuilder: (context, index) {
                final song = _visible[index];
                final checked = _picked.contains(song.id);
                return ListTile(
                  selected: checked,
                  selectedTileColor: primary.withValues(alpha: 0.1),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          color: primary.withValues(alpha: 0.1),
                          child: Icon(Iconsax.music, color: primary, size: 20),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist == null || song.artist == '<unknown>'
                        ? 'Unknown artist'
                        : song.artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Checkbox(
                    value: checked,
                    onChanged: (_) => setState(() {
                      if (!_picked.remove(song.id)) _picked.add(song.id);
                    }),
                  ),
                  onTap: () => setState(() {
                    if (!_picked.remove(song.id)) _picked.add(song.id);
                  }),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: count == 0 ? null : () => _commit(playNext: true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Play next'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: count == 0 ? null : () => _commit(playNext: false),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Add to queue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
