import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/playlists/playlist_picker_sheet.dart';
import 'package:kanyoni/features/tag_editor/tag_editor_page.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

/// The menu shown when a song is long-pressed in a list.
Future<void> showSongOptions(BuildContext context, SongModel song) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final player = Get.find<PlayerController>();

      Widget option(IconData icon, String label, VoidCallback onTap) {
        return ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.of(sheetContext).pop();
            onTap();
          },
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              option(Icons.playlist_play_rounded, 'Play next', () async {
                await player.playNextInQueue([song]);
                Get.snackbar(
                  'Queue',
                  'Will play next',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }),
              option(Icons.queue_music_rounded, 'Add to queue', () async {
                await player.addToQueue([song]);
                Get.snackbar(
                  'Queue',
                  'Added to queue',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }),
              option(Icons.playlist_add_rounded, 'Add to playlist', () {
                showSaveToPlaylistSheet(context, [
                  song,
                ], heading: 'Add to playlist');
              }),
              option(Icons.edit_rounded, 'Edit tags', () {
                TagEditorPage.open(context, song);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
