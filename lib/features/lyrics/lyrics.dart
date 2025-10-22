import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kanyoni/services/lyricsDb.dart';
import 'package:kanyoni/utils/theme/theme.dart';

class Lyrics extends StatelessWidget {
  final int songId;

  const Lyrics({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController addLyricsController = TextEditingController();
    LyricsDatabase lyricsDatabase = LyricsDatabase();

    return Scaffold(
      appBar: AppBar(
        // If you don't need anything on the left, you can remove leading
        title: Text('Lyrics', style: AppTheme.headlineMedium),
        centerTitle: true,

        // Right-side icons go here
        actions: [
          IconButton(
            onPressed: () {
              Get.dialog(AlertDialog(
                title: const Text('Delete Lyrics'),
                content:
                    const Text('Are you sure you want to delete the lyrics?'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      lyricsDatabase.deleteLyrics(songId);
                      if (kDebugMode) {
                        print("Lyrics deleted");
                      }
                      Get.back();
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ));
            },
            icon: Icon(
              Iconsax.trash,
              size: 25,
              color: Theme.of(context).primaryColor,
            ),
          ),
          IconButton(
            onPressed: () {
              String songLyrics;

              Get.dialog(AlertDialog(
                title: const Text('Add Lyrics'),
                content: TextField(
                  controller: addLyricsController,
                  decoration: InputDecoration(
                    hintText: 'Enter lyrics here',
                  ),
                  maxLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () => {
                      songLyrics = addLyricsController.text,

                      /// Save lyrics to hive database
                      lyricsDatabase.saveLyrics(songId, songLyrics),
                    },
                    child: const Text('OK'),
                  ),
                ],
              ));
            },
            icon: const Icon(
              Iconsax.add,
              size: 35,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Center(
            child: FutureBuilder<String?>(
              future: lyricsDatabase.getLyrics(songId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text(
                    "No lyrics available",
                  );
                } else {
                  return Text(
                    snapshot.data!,
                    style: AppTheme.headlineLarge,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
