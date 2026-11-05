import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/lyrics/lyrics_store.dart';
import 'package:kanyoni/features/playlists/controller/playlists_controller.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';

import 'song_tags.dart';
import 'tag_editor_service.dart';

/// Edit the title, artist, album, album artist, genre, year and track number
/// stored in a song's file.
class TagEditorPage extends StatefulWidget {
  final SongModel song;

  const TagEditorPage({super.key, required this.song});

  /// Opens the editor. Completes with true when tags were saved.
  static Future<bool?> open(BuildContext context, SongModel song) {
    return Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => TagEditorPage(song: song)));
  }

  @override
  State<TagEditorPage> createState() => _TagEditorPageState();
}

class _TagEditorPageState extends State<TagEditorPage> {
  final TagEditorService _service = TagEditorService();
  final Map<String, TextEditingController> _controllers = {
    for (final f in SongTags.fields) f: TextEditingController(),
  };

  SongTags _original = const SongTags();
  Map<String, String> _errors = {};
  bool _loading = true;
  bool _saving = false;

  bool get _editable => isEditableExtension(widget.song.fileExtension);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final song = widget.song;
    // What the library knows, then whatever the file itself says on top.
    final fromFile = await _service.readTags(song.id);

    String pick(String? fileValue, String? libraryValue) {
      final v = (fileValue ?? '').trim();
      if (v.isNotEmpty) return v;
      final lib = (libraryValue ?? '').trim();
      return lib == '<unknown>' ? '' : lib;
    }

    final tags = SongTags(
      title: pick(fromFile?.title, song.title),
      artist: pick(fromFile?.artist, song.artist),
      album: pick(fromFile?.album, song.album),
      albumArtist: fromFile?.albumArtist ?? '',
      genre: pick(fromFile?.genre, song.genre),
      year: fromFile?.year ?? '',
      track: fromFile?.track ?? (song.track != null ? '${song.track}' : ''),
    );

    _original = tags;
    tags.toMap().forEach((field, value) {
      _controllers[field]!.text = value;
    });
    if (mounted) setState(() => _loading = false);
  }

  SongTags _current() =>
      SongTags.fromMap({
        for (final e in _controllers.entries) e.key: e.value.text,
      }).copyWith(
        // fromMap tidies years read from files; keep exactly what was typed so
        // validation can reject bad input instead of hiding it.
        year: _controllers['year']!.text.trim(),
      );

  Future<void> _save() async {
    final edited = _current();
    final errors = edited.validate();
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    final changes = edited.changesFrom(_original);
    if (changes.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _errors = {};
      _saving = true;
    });

    final player = Get.find<PlayerController>();
    final resume = await player.releaseSongForEditing(widget.song.id);

    try {
      await _service.writeTags(widget.song.id, changes);
      // Lyrics are looked up by title/artist, so forget the old result.
      await LyricsStore.instance.deleteCached(widget.song.id);
      await player.restoreAfterEditing(resume);
      await player.onSongTagsEdited(widget.song.id);
      if (Get.isRegistered<PlaylistController>()) {
        // Playlists cache song metadata too.
        unawaited(Get.find<PlaylistController>().reloadSongs());
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
      Get.snackbar(
        'Tags saved',
        'Updated "${edited.title}"',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on TagWriteException catch (e) {
      // Even if saving failed, music must carry on where it was.
      await player.restoreAfterEditing(resume);
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        "Couldn't save tags",
        e.userMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      await player.restoreAfterEditing(resume);
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        "Couldn't save tags",
        'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _field(
    String field,
    String label, {
    TextInputType? keyboardType,
    int? maxLength,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: _controllers[field],
        enabled: _editable && !_saving,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) {
          if (_errors.containsKey(field)) {
            setState(() => _errors = Map.of(_errors)..remove(field));
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: _errors[field],
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _editable && !_loading && !_saving;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit tags'),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          ),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: canSave ? _save : null,
                child: const Text('Save'),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: QueryArtworkWidget(
                            id: widget.song.id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: Container(
                              color: Theme.of(context).primaryColor
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Iconsax.music,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.song.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_editable)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        ".${widget.song.fileExtension} files can't be edited. "
                        'Supported: MP3, FLAC, M4A, OGG and Opus.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Android will ask you to allow Kanyoni to modify this '
                        'file when you save. Leave a field empty to remove that tag.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  _field('title', 'Title', maxLength: SongTags.maxTextLength),
                  _field('artist', 'Artist', maxLength: SongTags.maxTextLength),
                  _field('album', 'Album', maxLength: SongTags.maxTextLength),
                  _field(
                    'albumArtist',
                    'Album artist',
                    maxLength: SongTags.maxTextLength,
                  ),
                  _field('genre', 'Genre', maxLength: SongTags.maxTextLength),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          'year',
                          'Year',
                          keyboardType: TextInputType.number,
                          hint: '2019',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'track',
                          'Track',
                          keyboardType: TextInputType.number,
                          hint: '3 or 3/12',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
