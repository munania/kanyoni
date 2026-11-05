import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'song_tags.dart';

/// Why a tag write failed, in words suitable for the user.
class TagWriteException implements Exception {
  final String code;
  final String? detail;

  const TagWriteException(this.code, [this.detail]);

  String get userMessage {
    switch (code) {
      case 'PERMISSION_DENIED':
        return 'Permission was not granted, so the song was not changed.';
      case 'UNSUPPORTED_FORMAT':
        return "This file type can't be edited.";
      case 'BUSY':
        return 'Another edit is still in progress. Try again in a moment.';
      case 'NO_ACTIVITY':
        return 'The app window is not available. Try again.';
      case 'WRITE_FAILED':
        return "Couldn't save the tags. Your original file was kept.";
      default:
        return 'Something went wrong while editing the tags.';
    }
  }

  @override
  String toString() => 'TagWriteException($code, $detail)';
}

/// Talks to `TagEditorHost.kt`.
class TagEditorService {
  static const MethodChannel _channel = MethodChannel('kanyoni/tags');

  /// Reads the tags stored *in the file* (MediaStore can differ, e.g. it
  /// shows the file name when there is no title tag). Null if unavailable.
  Future<SongTags?> readTags(int songId) async {
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readTags',
        {'id': songId},
      );
      return SongTags.fromMap(map);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) print('readTags failed: ${e.message}');
      return null;
    }
  }

  /// Writes [changes] (field -> new value, '' clears it). Shows Android's
  /// permission prompt when needed. Throws [TagWriteException] on failure.
  Future<void> writeTags(int songId, Map<String, String> changes) async {
    try {
      await _channel.invokeMethod<void>('writeTags', {
        'id': songId,
        'changes': changes,
      });
    } on PlatformException catch (e) {
      throw TagWriteException(e.code, e.message);
    } on MissingPluginException {
      throw const TagWriteException('UNSUPPORTED_FORMAT');
    }
  }
}
