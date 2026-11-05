import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'controller/playlists_controller.dart';

/// Bottom sheet that saves [songs] into an existing playlist or a brand new
/// one. Used by "Save queue as playlist" and "Add to playlist".
Future<void> showSaveToPlaylistSheet(
  BuildContext context,
  List<SongModel> songs, {
  String? heading,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SaveToPlaylistSheet(songs: songs, heading: heading),
  );
}

class _SaveToPlaylistSheet extends StatefulWidget {
  final List<SongModel> songs;
  final String? heading;

  const _SaveToPlaylistSheet({required this.songs, this.heading});

  @override
  State<_SaveToPlaylistSheet> createState() => _SaveToPlaylistSheetState();
}

class _SaveToPlaylistSheetState extends State<_SaveToPlaylistSheet> {
  final PlaylistController _playlists = Get.find<PlaylistController>();
  final TextEditingController _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _countLabel {
    final n = widget.songs.length;
    return '$n ${n == 1 ? 'song' : 'songs'}';
  }

  Future<void> _createAndSave() async {
    final problem = _playlists.validateName(_name.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });

    final created = await _playlists.createPlaylist(_name.text);
    if (created != null) {
      await _playlists.addSongsToPlaylist(created.id, widget.songs);
      if (mounted) Navigator.of(context).pop();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _saveTo(PlaylistModel playlist) async {
    setState(() => _busy = true);
    await _playlists.addSongsToPlaylist(playlist.id, widget.songs);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
      child: Column(
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
          Text(
            widget.heading ?? 'Save to playlist',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(_countLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),

          // New playlist
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _createAndSave(),
                  decoration: InputDecoration(
                    labelText: 'New playlist',
                    hintText: 'Playlist name',
                    errorText: _error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: _busy ? null : _createAndSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Or add to an existing playlist',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          Flexible(
            child: Obx(() {
              final lists = _playlists.playlists.toList();
              if (lists.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No playlists yet. Create one above.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final playlist = lists[index];
                  final count = _playlists.getPlaylistSongs(playlist.id).length;
                  return ListTile(
                    enabled: !_busy,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.music_playlist, color: primary),
                    ),
                    title: Text(playlist.playlist),
                    subtitle: Text('$count ${count == 1 ? 'song' : 'songs'}'),
                    onTap: () => _saveTo(playlist),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
