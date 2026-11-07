import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kanyoni/utils/helpers/saved_queue.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps the [SavedQueue] in a small file in the app's private storage.
///
/// A file rather than SharedPreferences: a queue can be thousands of ids, and
/// SharedPreferences loads everything into memory at start-up and rewrites its
/// whole file on every change.
class QueueStore {
  QueueStore._();

  static const String _fileName = 'queue_state.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<SavedQueue?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return SavedQueue.decode(await file.readAsString());
    } catch (e) {
      if (kDebugMode) print('QueueStore.load failed: $e');
      return null;
    }
  }

  /// Written to a temporary file and renamed into place, so being killed in
  /// the middle of a save can't leave a half-written (unreadable) queue.
  static Future<void> save(SavedQueue queue) async {
    try {
      final file = await _file();
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(queue.encode(), flush: true);
      await temp.rename(file.path);
    } catch (e) {
      if (kDebugMode) print('QueueStore.save failed: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
