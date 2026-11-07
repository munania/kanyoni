import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kanyoni/controllers/player_controller.dart';
import 'package:kanyoni/features/now_playing/now_playing_widgets.dart'
    show ThemedArtworkPlaceholder;
import 'package:on_audio_query_pluse/on_audio_query.dart';

/// Tiny, already-blurred copies of song artwork, shared by every page.
///
/// The background of every page is the playing song's artwork, blurred and
/// mostly covered by a tint. It used to be built per page from a 1000px,
/// quality-100 image plus a full-screen blur (sigma 30), re-requested on every
/// page push and song change. That is a lot of work for something that ends
/// up as a soft colour wash, and it was loaded asynchronously, so each rebuild
/// flashed an empty background first.
///
/// Instead: ask for a ~96px thumbnail, shrink it to [_imageSize]px, blur it
/// once at that tiny size, and keep the result in memory. Scaling the small
/// image up to the screen is smooth by itself, so no per-frame blur is needed,
/// and any page can show it on its very first frame.
class ArtworkBackdropCache {
  ArtworkBackdropCache._();
  static final ArtworkBackdropCache instance = ArtworkBackdropCache._();

  static const int _capacity = 40;
  static const int _imageSize = 48;

  final OnAudioQuery _query = OnAudioQuery();

  /// song id -> image. A null image means "this song has no artwork".
  final LinkedHashMap<int, ui.Image?> _images = LinkedHashMap<int, ui.Image?>();
  final Map<int, Future<ui.Image?>> _loading = {};

  /// True if [songId] has been loaded (even if it turned out to have no art),
  /// so [peek] can be used without waiting.
  bool has(int songId) => _images.containsKey(songId);

  /// The cached image, available immediately. Null if absent or art-less.
  ui.Image? peek(int songId) {
    if (!_images.containsKey(songId)) return null;
    final image = _images.remove(songId); // re-insert: most recently used
    _images[songId] = image;
    return image;
  }

  /// Loads (or joins an in-flight load of) the backdrop for [songId].
  Future<ui.Image?> load(int songId) {
    if (_images.containsKey(songId)) return Future.value(peek(songId));
    return _loading.putIfAbsent(
      songId,
      () => _create(songId).whenComplete(() => _loading.remove(songId)),
    );
  }

  /// Warm the cache without caring about the result.
  void prefetch(int songId) {
    if (!_images.containsKey(songId)) unawaited(load(songId));
  }

  Future<ui.Image?> _create(int songId) async {
    try {
      final bytes = await _query.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 96,
        quality: 60,
      );

      ui.Image? image;
      if (bytes != null && bytes.isNotEmpty) {
        image = await _blurredThumbnail(bytes);
      }
      _store(songId, image);
      return image;
    } catch (_) {
      // Not cached, so a later request can try again.
      return null;
    }
  }

  void _store(int songId, ui.Image? image) {
    _images.remove(songId);
    _images[songId] = image;
    // Evicted images are not disposed: one may still be on screen, and at
    // 48x48 they are tiny. The engine frees them when they are unreachable.
    while (_images.length > _capacity) {
      _images.remove(_images.keys.first);
    }
  }

  static Future<ui.Image> _blurredThumbnail(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _imageSize,
    );
    final frame = await codec.getNextFrame();
    final source = frame.image;
    final width = source.width;
    final height = source.height;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bounds = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    // Blur at the tiny size; scaled up to a screen this is a very wide blur.
    canvas.saveLayer(
      bounds,
      ui.Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: 2.5,
          sigmaY: 2.5,
          tileMode: ui.TileMode.clamp,
        ),
    );
    canvas.drawImage(
      source,
      ui.Offset.zero,
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final result = await picture.toImage(width, height);
    picture.dispose();
    source.dispose();
    codec.dispose();
    return result;
  }
}

/// The page background: the playing song's artwork, softly blurred and
/// tinted with the theme colour. Put it first in a page's `Stack`.
///
/// It follows the current song by itself, so a page doesn't have to rebuild
/// just to change its background. When the song changes the previous image
/// stays until the next one is ready and then cross-fades, so it never flashes.
class ArtworkBackdrop extends StatefulWidget {
  const ArtworkBackdrop({super.key});

  @override
  State<ArtworkBackdrop> createState() => _ArtworkBackdropState();
}

class _ArtworkBackdropState extends State<ArtworkBackdrop> {
  final PlayerController _player = Get.find<PlayerController>();
  final ArtworkBackdropCache _cache = ArtworkBackdropCache.instance;
  final List<Worker> _workers = [];

  int? _songId;
  int? _shownSongId;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _workers.addAll([
      ever(_player.currentSongIndex, (_) => _update()),
      ever(_player.currentPlaylist, (_) => _update()),
    ]);
    _update(initial: true);
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }

  void _update({bool initial = false}) {
    final id = _player.activeSong?.id;
    if (id == _songId && !initial) return;
    _songId = id;

    void apply(int? songId, ui.Image? image) {
      if (initial) {
        _shownSongId = songId;
        _image = image;
      } else if (mounted) {
        setState(() {
          _shownSongId = songId;
          _image = image;
        });
      }
    }

    if (id == null) {
      apply(null, null);
      return;
    }

    if (_cache.has(id)) {
      // Already known: show it right now, on this very frame.
      apply(id, _cache.peek(id));
    } else {
      // Keep the previous image on screen until this one is ready.
      _cache.load(id).then((image) {
        if (mounted && _songId == id) apply(id, image);
      });
    }

    // Have the next song's ready too.
    final next = _player.currentSongIndex.value + 1;
    if (next >= 0 && next < _player.currentPlaylist.length) {
      _cache.prefetch(_player.currentPlaylist[next].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_songId == null)
            const ThemedArtworkPlaceholder(iconSize: 120)
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _image == null
                  ? ColoredBox(
                      key: const ValueKey<int>(-1),
                      color: scaffoldColor,
                    )
                  : SizedBox.expand(
                      key: ValueKey<int>(_shownSongId ?? -1),
                      child: RawImage(
                        image: _image,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
            ),
          // The tint that used to sit on top of the runtime blur.
          ColoredBox(
            color: scaffoldColor.withValues(alpha: isDarkMode ? 0.7 : 0.85),
          ),
          ColoredBox(color: theme.primaryColor.withValues(alpha: 0.05)),
        ],
      ),
    );
  }
}
