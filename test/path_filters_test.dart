import 'package:flutter_test/flutter_test.dart';
import 'package:kanyoni/utils/helpers/path_filters.dart';

void main() {
  group('isInBlacklistedFolder', () {
    const blacklist = ['/storage/emulated/0/Music/Rock'];

    test('matches files inside the folder and its sub-folders', () {
      expect(
        isInBlacklistedFolder(
          '/storage/emulated/0/Music/Rock/a.mp3',
          blacklist,
        ),
        isTrue,
      );
      expect(
        isInBlacklistedFolder(
          '/storage/emulated/0/Music/Rock/Live/a.mp3',
          blacklist,
        ),
        isTrue,
      );
    });

    test('does not match a folder that merely shares the prefix', () {
      expect(
        isInBlacklistedFolder(
          '/storage/emulated/0/Music/Rockabilly/a.mp3',
          blacklist,
        ),
        isFalse,
      );
    });

    test('handles trailing slashes and empty entries', () {
      expect(isInBlacklistedFolder('/a/b/c.mp3', ['/a/b/']), isTrue);
      expect(isInBlacklistedFolder('/a/b/c.mp3', ['']), isFalse);
    });
  });

  group('isTooShort', () {
    test('compares in seconds and keeps unknown durations', () {
      expect(isTooShort(29000, 30), isTrue);
      expect(isTooShort(30000, 30), isFalse);
      expect(isTooShort(null, 30), isFalse);
      expect(isTooShort(1000, 0), isFalse);
    });
  });
}
